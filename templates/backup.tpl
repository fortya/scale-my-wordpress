# backup the full application including static files
export SMW_GROUP=
export SMW_PATH=
export SMW_WP_CONFIG_BUCKET=
export SMW_WP_ASSETS_BUCKET=

aws s3 sync $SMW_PATH s3://$SMW_WP_CONFIG_BUCKET --exclude "wp-content/*" --exclude "wp-includes/*" --exclude "wp-config.php"
aws s3 sync $SMW_PATH/wp-includes/ s3://$SMW_WP_ASSETS_BUCKET/wp-includes/
aws s3 sync $SMW_PATH/wp-content/ s3://$SMW_WP_ASSETS_BUCKET/wp-content/


# forward query args on wp-includes/
