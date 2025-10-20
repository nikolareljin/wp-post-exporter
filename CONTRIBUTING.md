Contributing

Development setup
- PHP 8.0+ recommended (min 7.4)
- Composer for dev tooling

Install dev dependencies

```
cd wp-post-exporter
composer install
```

Linting

```
composer run lint
composer run lint:fix
```

Build ZIP (respects .distignore)

```
cd wp-post-exporter
bash bin/build-zip.sh
```

Release to WordPress.org
- Tag a release in Git (e.g., v1.0.0)
- GitHub Actions workflow `Deploy to WordPress.org` uses secrets `SVN_USERNAME` and `SVN_PASSWORD`
- Ensure assets/ contains banner/icon images per assets/ASSETS.md

Packagist
- Submit the GitHub repository to Packagist with name `nikolareljin/wp-post-exporter`
- Packagist will auto-update on tags; `type: wordpress-plugin` is set for installers

