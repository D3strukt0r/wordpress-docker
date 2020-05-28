# wordpress-php & wordpress-nginx

Wordpress inside Docker.

## Getting Started

These instructions will cover usage information and for the docker container

### Prerequisities

In order to run this container you'll need docker installed.

-   [Windows](https://docs.docker.com/docker-for-windows/install/)
-   [OS X](https://docs.docker.com/docker-for-mac/install/)
-   [Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

### Usage

#### Container Parameters

```shell
docker run -v $PWD/uploads:/data/wp-content/uploads -e DB_PASSWORD=password -e <all the keys> d3strukt0r/wordpress-php
```
```shell
docker run -p 80:80 -v $PWD/uploads:/data/wp-content/uploads d3strukt0r/wordpress-nginx
```

#### Environment Variables

_PHP_

-   `UPLOAD_LIMIT` - The upload limit on the website (has to be the same on php and nginx) (Default: `10M`)
-   `DB_HOST` - Host of the DBMS (Default: `db`)
-   `DB_PORT` - Port of the DBMS (Default: `3306`)
-   `DB_USER` - The username to use in the DBMS (Default: `root`)
-   `DB_PASSWORD` - The password to use in the DBMS (Default: ) (Required)
-   `DB_NAME` - The database name in the DBMS (Default: `wordpress`)
-   `DB_CHARSET` - The character set to use in the DBMS (Default: `utf8mb4`)
-   `DB_COLLATE` - The collation to use in the DBMS (Default: `utf8mb4_unicode_ci`)
-   `DB_TABLE_PREFIX` - The table prefix to use in the DBMS (Default: `wp_`) (Hint: Cannot be empty)
-   `WP_AUTH_KEY` - Key (Default: ) (Required)
-   `WP_SECURE_AUTH_KEY` - Key (Default: ) (Required)
-   `WP_LOGGED_IN_KEY` - Key (Default: ) (Required)
-   `WP_NONCE_KEY` - Key (Default: ) (Required)
-   `WP_AUTH_SALT` - Salt (Default: ) (Required)
-   `WP_SECURE_AUTH_SALT` - Salt (Default: ) (Required)
-   `WP_LOGGED_IN_SALT` - Salt (Default: ) (Required)
-   `WP_NONCE_SALT` - Salt (Default: ) (Required)
-   `WP_DEBUG` - Whether to enable debug mode (Default: `false`)

_Nginx_

-   `UPLOAD_LIMIT` - The upload limit on the website (has to be the same on php and nginx) (Default: `10M`)
-   `USE_HTTPS` - Enables https. (Not recommeded, rather use Traefik) (Default: `false`)

#### Volumes

-   `/data` - All the data
-   `/data/wp-config.php` - Will use default wp-confing.php or the one on /data if provided
-   `/data/wp-content/` - Contains plugins, themes, uploads, etc.
-   `/data/wp-content/uploads` - Contains all user uploads (Recommended to connect)

#### Useful File Locations

_PHP_

-   `/usr/local/bin/wp-plugin-install.sh` - Installs a plugin from wordpress in the current directory
-   `/usr/local/bin/wp-theme-install.sh` - Installs a theme from wordpress in the current directory

## Built With

-   [Wordpress](https://wordpress.org/) - The main software
-   [Travis CI](https://travis-ci.com/) - Automatic CI (Testing) / CD (Deployment)
-   [Docker](https://www.docker.com/) - Building a Container for the Server

## Find Us

-   [GitHub](https://github.com/D3strukt0r/docker-wordpress)
-   [Docker Hub](https://hub.docker.com/r/d3strukt0r/wordpress)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

There is no versioning in this project. Only the develop for nightly builds, and the master branch which builds latest and all minecraft versions.

## Authors

-   **Manuele Vaccari** - [D3strukt0r](https://github.com/D3strukt0r) - _Initial work_

See also the list of [contributors](https://github.com/D3strukt0r/docker-wordpress/contributors) who
participated in this project.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.txt](LICENSE.txt) file for details.

## Acknowledgments

-   Hat tip to anyone whose code was used
-   Inspiration
-   etc
