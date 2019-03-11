# Apache with PHP 7.0 on Jessie

Legacy php7.0 image, source provided by United Internet 1&1

In order to get the latest php7.0 build from UI, you will need to
1. Clone https://git.dev.glo.gb/cloudhostingpublic/legacy-php-build
2. PHP_VERSION=7.0 make -e
3. commit the new deb
4. push back to the repo

Building this image will then pull the new deb.
