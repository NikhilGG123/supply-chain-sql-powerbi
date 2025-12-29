"""
Supply Chain Data Import Pipeline

ETL pipeline for importing supply chain data from CSV to PostgreSQL.
Processes 180K+ transactions with deduplication and foreign key management.

Author: [Your Name]
Date: December 2025
"""

import pandas as pd
import psycopg2
from datetime import datetime
from pathlib import Path
import sys
import os
from typing import Dict, Optional
from dotenv import load_dotenv

load_dotenv()

CONFIG = {
    'csv_file': os.getenv('CSV_FILE_PATH', r'C:\supply-chain-sql-powerbi\data\DataCoSupplyChainDataset.csv'),
    'db_config': {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': int(os.getenv('DB_PORT', 5432)),
        'database': os.getenv('DB_NAME', 'supply_chain_analytics'),
        'user': os.getenv('DB_USER', 'postgres'),
        'password': os.getenv('DB_PASSWORD', '')
    },
    'batch_size': int(os.getenv('BATCH_SIZE', 1000))
}


class SupplyChainImporter:
    """Handles ETL pipeline from CSV to PostgreSQL database."""
    
    def __init__(self, config: dict):
        self.config = config
        self.conn: Optional[psycopg2.connection] = None
        self.df: Optional[pd.DataFrame] = None
        
    def connect_database(self) -> None:
        """Establish database connection."""
        try:
            self.conn = psycopg2.connect(**self.config['db_config'])
            print(f"✓ Connected to {self.config['db_config']['database']}")
        except psycopg2.Error as e:
            print(f"✗ Connection failed: {e}")
            sys.exit(1)
    
    def load_csv(self) -> None:
        """Load source CSV file."""
        print("\n[1/5] Loading CSV...")
        
        try:
            csv_path = Path(self.config['csv_file'])
            if not csv_path.exists():
                raise FileNotFoundError(f"CSV not found: {csv_path}")
            
            self.df = pd.read_csv(csv_path, encoding='latin-1', low_memory=False)
            print(f"✓ Loaded {len(self.df):,} rows, {len(self.df.columns)} columns")
            
        except Exception as e:
            print(f"✗ Failed: {e}")
            sys.exit(1)
    
    @staticmethod
    def clean_numeric(value) -> Optional[float]:
        """Convert to float, return None if invalid."""
        try:
            return None if pd.isna(value) else float(value)
        except (ValueError, TypeError):
            return None
    
    @staticmethod
    def clean_int(value) -> Optional[int]:
        """Convert to integer, return None if invalid."""
        try:
            return None if pd.isna(value) else int(float(value))
        except (ValueError, TypeError):
            return None
    
    def import_customers(self) -> Dict[int, int]:
        """
        Import customer records with deduplication.
        Returns mapping of source Customer ID to database customer_id.
        """
        print("\n[2/5] Importing Customers...")
        
        cursor = self.conn.cursor()
        
        # Extract customer columns
        customer_cols = [
            'Customer Id', 'Customer Email', 'Customer Fname', 'Customer Lname',
            'Customer Segment', 'Customer City', 'Customer State', 'Customer Country',
            'Customer Zipcode', 'Customer Street', 'Latitude', 'Longitude'
        ]
        
        customers = self.df[[col for col in customer_cols if col in self.df.columns]].copy()
        customers = customers[customers['Customer Id'].notna()]
        
        # Deduplicate by Customer ID
        customers_unique = customers.groupby('Customer Id', as_index=False).first()
        print(f"  Unique customers: {len(customers_unique):,}")
        
        insert_query = """
            INSERT INTO customers (
                customer_email, customer_fname, customer_lname, customer_segment,
                customer_city, customer_state, customer_country, customer_zipcode,
                customer_street, latitude, longitude
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING customer_id
        """
        
        customer_map = {}
        imported = 0
        
        for _, row in customers_unique.iterrows():
            try:
                source_id = int(row['Customer Id'])
                email = str(row.get('Customer Email', f'customer_{source_id}@placeholder.com'))
                
                cursor.execute(insert_query, (
                    email,
                    str(row.get('Customer Fname', '')),
                    str(row.get('Customer Lname', '')),
                    str(row.get('Customer Segment', '')) if pd.notna(row.get('Customer Segment')) else None,
                    str(row.get('Customer City', '')) if pd.notna(row.get('Customer City')) else None,
                    str(row.get('Customer State', '')) if pd.notna(row.get('Customer State')) else None,
                    str(row.get('Customer Country', '')) if pd.notna(row.get('Customer Country')) else None,
                    str(row.get('Customer Zipcode', '')) if pd.notna(row.get('Customer Zipcode')) else None,
                    str(row.get('Customer Street', '')) if pd.notna(row.get('Customer Street')) else None,
                    self.clean_numeric(row.get('Latitude')),
                    self.clean_numeric(row.get('Longitude'))
                ))
                
                result = cursor.fetchone()
                if result:
                    customer_map[source_id] = result[0]
                    imported += 1
                    
                if imported % 1000 == 0:
                    self.conn.commit()
                    print(f"  Progress: {imported:,}", end='\r')
                    
            except Exception:
                continue
        
        self.conn.commit()
        print(f"\n✓ Imported {imported:,}")
        return customer_map
    
    def import_products(self) -> Dict[str, int]:
        """
        Import product catalog with deduplication.
        Returns mapping of product name to database product_id.
        """
        print("\n[3/5] Importing Products...")
        
        cursor = self.conn.cursor()
        
        product_cols = [
            'Product Name', 'Product Card Id', 'Category Name', 'Department Name',
            'Product Price', 'Product Description', 'Product Image', 'Product Status'
        ]
        
        products = self.df[[col for col in product_cols if col in self.df.columns]].copy()
        products['Product Name'] = products['Product Name'].astype(str).str.strip()
        products = products[
            (products['Product Name'].notna()) &
            (products['Product Name'] != 'nan') &
            (products['Product Name'] != '')
        ]
        
        products_unique = products.groupby('Product Name', as_index=False).first()
        print(f"  Unique products: {len(products_unique):,}")
        
        insert_query = """
            INSERT INTO products (
                product_name, product_card_id, category_name, department_name,
                product_price, product_description, product_image, product_status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING product_id, product_name
        """
        
        product_map = {}
        imported = 0
        
        for _, row in products_unique.iterrows():
            try:
                product_name = str(row['Product Name']).strip()
                
                cursor.execute(insert_query, (
                    product_name,
                    self.clean_int(row.get('Product Card Id')),
                    str(row.get('Category Name', '')) if pd.notna(row.get('Category Name')) else None,
                    str(row.get('Department Name', '')) if pd.notna(row.get('Department Name')) else None,
                    self.clean_numeric(row.get('Product Price')),
                    str(row.get('Product Description', '')) if pd.notna(row.get('Product Description')) else None,
                    str(row.get('Product Image', '')) if pd.notna(row.get('Product Image')) else None,
                    self.clean_int(row.get('Product Status'))
                ))
                
                result = cursor.fetchone()
                if result:
                    product_map[product_name] = result[0]
                    imported += 1
                    
            except Exception:
                continue
        
        self.conn.commit()
        print(f"✓ Imported {imported:,}")
        return product_map
    
    def import_orders(self, customer_map: Dict[int, int], product_map: Dict[str, int]) -> Dict[int, int]:
        """
        Import order transactions with foreign key resolution.
        Returns mapping of DataFrame index to database order_id.
        """
        print("\n[4/5] Importing Orders...")
        
        cursor = self.conn.cursor()
        
        insert_query = """
            INSERT INTO orders (
                order_item_id, customer_id, product_id, order_date, order_date_dateorders,
                order_quantity, sales, discount, profit_per_order, order_status,
                market, order_region, order_country, order_city, order_state, order_zipcode
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING order_id
        """
        
        order_map = {}
        processed = 0
        skipped = {'no_customer': 0, 'no_product': 0, 'error': 0}
        
        for idx, row in self.df.iterrows():
            source_customer_id = int(row['Customer Id']) if pd.notna(row.get('Customer Id')) else None
            product_name = str(row.get('Product Name', '')).strip() if pd.notna(row.get('Product Name')) else None
            
            customer_id = customer_map.get(source_customer_id)
            product_id = product_map.get(product_name)
            
            if not customer_id:
                skipped['no_customer'] += 1
                continue
            if not product_id:
                skipped['no_product'] += 1
                continue
            
            try:
                cursor.execute(insert_query, (
                    self.clean_int(row.get('Order Item Id')),
                    customer_id,
                    product_id,
                    str(row.get('order date (DateOrders)', '')) if pd.notna(row.get('order date (DateOrders)')) else None,
                    str(row.get('order date (DateOrders)', '')) if pd.notna(row.get('order date (DateOrders)')) else None,
                    self.clean_int(row.get('Order Item Quantity')),
                    self.clean_numeric(row.get('Sales per customer')),
                    self.clean_numeric(row.get('Order Item Discount')),
                    self.clean_numeric(row.get('Order Profit Per Order')),
                    str(row.get('Order Status', '')) if pd.notna(row.get('Order Status')) else None,
                    str(row.get('Market', '')) if pd.notna(row.get('Market')) else None,
                    str(row.get('Order Region', '')) if pd.notna(row.get('Order Region')) else None,
                    str(row.get('Order Country', '')) if pd.notna(row.get('Order Country')) else None,
                    str(row.get('Order City', '')) if pd.notna(row.get('Order City')) else None,
                    str(row.get('Order State', '')) if pd.notna(row.get('Order State')) else None,
                    str(row.get('Order Zipcode', '')) if pd.notna(row.get('Order Zipcode')) else None
                ))
                
                result = cursor.fetchone()
                if result:
                    order_map[idx] = result[0]
                    processed += 1
                    
                if processed % self.config['batch_size'] == 0:
                    self.conn.commit()
                    print(f"  Progress: {processed:,}", end='\r')
                    
            except psycopg2.Error:
                skipped['error'] += 1
                continue
        
        self.conn.commit()
        print(f"\n✓ Imported {processed:,}")
        
        total = sum(skipped.values())
        if total > 0:
            print(f"  Skipped {total:,}: {skipped['no_customer']:,} missing customer, "
                  f"{skipped['no_product']:,} missing product, {skipped['error']:,} errors")
        
        return order_map
    
    def import_shipping(self, order_map: Dict[int, int]) -> None:
        """Import shipping records linked to orders."""
        print("\n[5/5] Importing Shipping...")
        
        cursor = self.conn.cursor()
        
        insert_query = """
            INSERT INTO shipping_details (
                order_id, shipping_date, shipping_mode, days_for_shipping_real,
                days_for_shipment_scheduled, delivery_status, late_delivery_risk
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        
        processed = 0
        skipped = 0
        
        for idx, row in self.df.iterrows():
            order_id = order_map.get(idx)
            if not order_id:
                skipped += 1
                continue
            
            try:
                cursor.execute(insert_query, (
                    order_id,
                    str(row.get('shipping date (DateOrders)', '')) if pd.notna(row.get('shipping date (DateOrders)')) else None,
                    str(row.get('Shipping Mode', '')) if pd.notna(row.get('Shipping Mode')) else None,
                    self.clean_int(row.get('Days for shipping (real)')),
                    self.clean_int(row.get('Days for shipment (scheduled)')),
                    str(row.get('Delivery Status', '')) if pd.notna(row.get('Delivery Status')) else None,
                    self.clean_int(row.get('Late_delivery_risk'))
                ))
                
                processed += 1
                
                if processed % self.config['batch_size'] == 0:
                    self.conn.commit()
                    print(f"  Progress: {processed:,}", end='\r')
                    
            except psycopg2.Error:
                skipped += 1
                continue
        
        self.conn.commit()
        print(f"\n✓ Imported {processed:,}")
        if skipped > 0:
            print(f"  Skipped {skipped:,} (no matching order)")
    
    def verify_import(self) -> None:
        """Display import summary and key metrics."""
        print("\n" + "="*60)
        print("Import Summary")
        print("="*60)
        
        cursor = self.conn.cursor()
        
        print("\nTable Counts:")
        for table in ['customers', 'products', 'orders', 'shipping_details']:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"  {table:20s} {count:>12,}")
        
        print("\nBusiness Metrics:")
        cursor.execute("""
            SELECT 
                COUNT(DISTINCT order_id),
                ROUND(SUM(sales)::numeric, 2),
                ROUND(AVG(sales)::numeric, 2),
                SUM(order_quantity)
            FROM orders
        """)
        
        metrics = cursor.fetchone()
        if metrics and metrics[0]:
            print(f"  Orders               {metrics[0]:>12,}")
            print(f"  Revenue           ${metrics[1]:>13,}")
            print(f"  Avg Order         ${metrics[2]:>13,}")
            print(f"  Units                {metrics[3]:>12,}")
        
        print("\nDelivery Performance:")
        cursor.execute("""
            SELECT 
                SUM(CASE WHEN late_delivery_risk = 1 THEN 1 ELSE 0 END),
                SUM(CASE WHEN late_delivery_risk = 0 THEN 1 ELSE 0 END),
                ROUND((SUM(CASE WHEN late_delivery_risk = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*))::numeric, 2)
            FROM shipping_details
        """)
        
        delivery = cursor.fetchone()
        if delivery and delivery[0] is not None:
            print(f"  Late                 {delivery[0]:>12,}")
            print(f"  On-Time              {delivery[1]:>12,}")
            print(f"  On-Time Rate         {delivery[2]:>11}%")
        
        print("="*60)
    
    def run(self) -> None:
        """Execute full ETL pipeline."""
        start = datetime.now()
        
        print("\nSupply Chain Data Import")
        print("="*60)
        
        try:
            self.connect_database()
            self.load_csv()
            
            customer_map = self.import_customers()
            product_map = self.import_products()
            order_map = self.import_orders(customer_map, product_map)
            self.import_shipping(order_map)
            
            self.verify_import()
            
            elapsed = (datetime.now() - start).total_seconds()
            print(f"\n✓ Completed in {elapsed:.1f}s")
            
            print("\nNext Steps:")
            print("  1. Run sql/03_create_views.sql to create analytical views")
            print("  2. Connect Power BI to PostgreSQL")
            print("  3. Build dashboards")
            
        except Exception as e:
            print(f"\n✗ Failed: {e}")
            import traceback
            traceback.print_exc()
            if self.conn:
                self.conn.rollback()
        finally:
            if self.conn:
                self.conn.close()


def main():
    """Entry point."""
    importer = SupplyChainImporter(CONFIG)
    importer.run()


if __name__ == "__main__":
    main()
