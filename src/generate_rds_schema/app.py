import sys
import logging
import rds_config
import pymysql

#rds settings
name = rds_config.db_username
password = rds_config.db_password
db_name = rds_config.db_name
port = 3306

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    rds_host = event['DB_HOST']
    try:
        conn = pymysql.connect(host=rds_host, user=name, password=password, database=db_name, port=port, connect_timeout=5)
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        sys.exit()

    logger.info("SUCCESS: Connection to RDS MySQL instance succeeded")
    item_count = 0

    with conn.cursor() as cur:
        cur.execute("use test")
        cur.execute("CREATE TABLE IF NOT EXISTS users (id int(11) NOT NULL auto_increment, name varchar(100) NOT NULL, age int(3) NOT NULL, email varchar(100) NOT NULL, PRIMARY KEY (id))")
        conn.commit()
    conn.commit()

    return "Added schema from RDS MySQL table"