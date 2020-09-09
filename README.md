# wordpress-php & wordpress-nginx

Wordpress inside Docker.

Project

[![License](https://img.shields.io/github/license/d3strukt0r/docker-wordpress)][license]
[![Docker Stars](https://img.shields.io/docker/stars/d3strukt0r/wordpress-nginx.svg?label=docker%20stars%20(nginx))][docker-nginx]
[![Docker Pulls](https://img.shields.io/docker/pulls/d3strukt0r/wordpress-nginx.svg?label=docker%20pulls%20(nginx))][docker-nginx]
[![Docker Stars](https://img.shields.io/docker/stars/d3strukt0r/wordpress-php.svg?label=docker%20stars%20(php))][docker-php]
[![Docker Pulls](https://img.shields.io/docker/pulls/d3strukt0r/wordpress-php.svg?label=docker%20pulls%20(php))][docker-php]

master-branch (alias stable, latest)

[![GH Action CI/CD](https://github.com/D3strukt0r/docker-wordpress/workflows/CI/CD/badge.svg?branch=master)][gh-action]
[![Codacy grade](https://img.shields.io/codacy/grade/17d3bf5aebda47ababb0e156bab78c4e/master)][codacy]

<!--
develop-branch (alias nightly)

[![GH Action CI/CD](https://github.com/D3strukt0r/docker-wordpress/workflows/CI/CD/badge.svg?branch=develop)][gh-action]
[![Codacy grade](https://img.shields.io/codacy/grade/17d3bf5aebda47ababb0e156bab78c4e/develop)][codacy]
-->

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
docker run -v $PWD/uploads:/app/wp-content/uploads -e DB_PASSWORD=password -e <all the keys> d3strukt0r/wordpress-php
```

```shell
docker run -p 80:80 -v $PWD/uploads:/app/wp-content/uploads d3strukt0r/wordpress-nginx
```

#### Environment Variables

##### PHP Envs

###### PHP settings

-   `PHP_MAX_EXECUTION_TIME` - The maximum time php can run per request (Default: `100M`)
-   `PHP_MEMORY_LIMIT` - The memory limit that php can use (Default: `256M`)
-   `PHP_POST_MAX_SIZE` - The maximum size for sending POST requests (maximum upload size) (has to be the same on nginx) (Default: `100M`)
-   `PHP_UPLOAD_MAX_FILESIZE` - The maximum size per file for uploading (Default: `100M`)

###### Database settings

-   `DB_HOST` - Host of the DBMS (Default: `db`)
-   `DB_PORT` - Port of the DBMS (Default: `3306`)
-   `DB_USER` - The username to use in the DBMS (Default: `root`)
-   `DB_PASSWORD` - The password to use in the DBMS (Default: ) (Required)
-   `DB_NAME` - The database name in the DBMS (Default: `wordpress`)
-   `DB_CHARSET` - The character set to use in the DBMS (Default: `utf8mb4`)
-   `DB_COLLATE` - The collation to use in the DBMS (Default: `utf8mb4_unicode_ci`)
-   `DB_TABLE_PREFIX` - The table prefix to use in the DBMS (Default: `wp_`) (Hint: Cannot be empty)

###### Wordpress secrets

-   `WP_AUTH_KEY` - Key (Default: ) (Required)
-   `WP_SECURE_AUTH_KEY` - Key (Default: ) (Required)
-   `WP_LOGGED_IN_KEY` - Key (Default: ) (Required)
-   `WP_NONCE_KEY` - Key (Default: ) (Required)
-   `WP_AUTH_SALT` - Salt (Default: ) (Required)
-   `WP_SECURE_AUTH_SALT` - Salt (Default: ) (Required)
-   `WP_LOGGED_IN_SALT` - Salt (Default: ) (Required)
-   `WP_NONCE_SALT` - Salt (Default: ) (Required)

###### Other wordpress settings

-   `WP_DEBUG` - Whether to enable debug mode (Default: `false`)

##### Nginx Envs

-   `NGINX_CLIENT_MAX_BODY_SIZE` - The maximum size for sending POST requests (maximum upload size) (has to be the same on php) (Default: `100M`)
-   `USE_HTTPS` - Enables https. (Not recommeded, rather use Traefik) (Default: `false`)

#### Volumes

-   `/app` - All the data
-   `/app/wp-config.php` - Will use default wp-confing.php or the one on /data if provided
-   `/app/wp-content/` - Contains plugins, themes, uploads, etc.
-   `/app/wp-content/uploads` - Contains all user uploads (Recommended to connect)

#### Useful File Locations

##### PHP Files

-   `/usr/local/bin/wp-plugin-install` - Installs a plugin from wordpress in the current directory
-   `/usr/local/bin/wp-theme-install` - Installs a theme from wordpress in the current directory

## Built With

-   [Wordpress](https://wordpress.org/) - The main software
-   [Github Actions](https://github.com/features/actions) - Automatic CI (Testing) / CD (Deployment)
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

[license]: https://github.com/D3strukt0r/docker-wordpress/blob/master/LICENSE.txt
[docker-nginx]: https://hub.docker.com/repository/docker/d3strukt0r/wordpress-nginx
[docker-php]: https://hub.docker.com/repository/docker/d3strukt0r/wordpress-php
[gh-action]: https://github.com/D3strukt0r/docker-wordpress/actions
[codacy]: https://app.codacy.com/manual/D3strukt0r/docker-wordpress/dashboard
