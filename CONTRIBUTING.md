Contributing

Development setup
- PHP 8.0+ recommended (min 7.4)
- Composer for dev tooling

Install dev dependencies

```
cd nr-post-exporter
composer install
```

Linting

```
composer run lint
composer run lint:fix
```

Build ZIP (respects .distignore)

```
cd nr-post-exporter
bash bin/build-zip.sh
```

Release to WordPress.org
- Tag a release in Git (e.g., v1.0.0)
- GitHub Actions workflow `Deploy to WordPress.org` uses secrets `SVN_USERNAME` and `SVN_PASSWORD`
- Ensure assets/ contains banner/icon images per assets/ASSETS.md

Packagist
- Submit the GitHub repository to Packagist with name `nikolareljin/nr-post-exporter`
- Packagist will auto-update on tags; `type: wordpress-plugin` is set for installers

Repository rename
- The project has been renamed to `nr-post-exporter`. To update your local git remote:

```
bash bin/update-remote.sh
# or specify a custom URL
bash bin/update-remote.sh origin https://github.com/nikolareljin/nr-post-exporter.git
```
