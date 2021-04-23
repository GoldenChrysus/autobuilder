#!/bin/bash

set -e
set -u

# Globals
ORIGIN_DIR="origin"
DESTINATION_DIR="desto"

# Setup git
echo "Setting up git..."
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"
echo "Setup git..."

# Clone origin repository
echo "Cloning origin repository..."
rm -rf $ORIGIN_DIR
git clone --single-branch --branch "$GIT_ORIGIN_BRANCH" "https://$GIT_TOKEN@github.com/$GIT_USER/$GIT_ORIGIN_REPO.git" "$ORIGIN_DIR"

cd $ORIGIN_DIR
echo "Cloned origin repository..."

# Build SSL repo
echo "Building for $GIT_DESTINATION_REPO..."

cat << EOF > .env-cmdrc
{
	"default": {
		"REACT_APP_ROUTER_BASE": "",
		"REACT_APP_HTTP_BASE": "$REACT_APP_HTTP_BASE",
		"REACT_APP_REDIRECT_URL": "$REACT_APP_REDIRECT_URL",
		"REACT_APP_VERSION": "$REACT_APP_VERSION",
		"REACT_APP_GITHUB_URL": "$REACT_APP_GITHUB_URL",
		"REACT_APP_DISCORD_URL": "$REACT_APP_DISCORD_URL",
		"REACT_APP_AUTHOR_URL": "$REACT_APP_AUTHOR_URL",
		"REACT_APP_CHANGELOG_URL": "$REACT_APP_CHANGELOG_URL",
		"REACT_APP_TWITCH_API_CLIENT_ID": "$REACT_APP_TWITCH_API_CLIENT_ID",
		"REACT_APP_CASH_DONATE_LINK": "$REACT_APP_CASH_DONATE_LINK",
		"REACT_APP_PAYPAL_DONATE_LINK": "$REACT_APP_PAYPAL_DONATE_LINK",
		"REACT_APP_STREAMLABS_DONATE_LINK": "$REACT_APP_STREAMLABS_DONATE_LINK",
		"REACT_APP_KOFI_DONATE_LINK": "$REACT_APP_KOFI_DONATE_LINK",
		"REACT_APP_PATREON_DONATE_LINK": "$REACT_APP_PATREON_DONATE_LINK",
		"REACT_APP_PAYPAY_DONATE_LINK": "$REACT_APP_PAYPAY_DONATE_LINK",
		"REACT_APP_PAYPAY_DONATE_ID": "$REACT_APP_PAYPAY_DONATE_ID",
		"REACT_APP_PAGE_TITLE": "$REACT_APP_PAGE_TITLE",
		"REACT_APP_GOOGLE_TAG_MANAGER_ID": "$REACT_APP_GOOGLE_TAG_MANAGER_ID",
		"REACT_APP_ENV": "$BUILD_TYPE"
	},
	"nonssl": {
		"REACT_APP_GOOGLE_TAG_MANAGER_ID": "$REACT_APP_NONSSL_GOOGLE_TAG_MANAGER_ID"
	}
}
EOF

npm i
npm run build$BUILD_SSL

cd ../
echo "Built for $GIT_DESTINATION_REPO..."

# Clone destination repository
echo "Cloning destination repository..."
rm -rf $DESTINATION_DIR
git clone --single-branch --branch "master" "https://$GIT_TOKEN@github.com/$GIT_USER/$GIT_DESTINATION_REPO.git" "$DESTINATION_DIR"

cd $DESTINATION_DIR
echo "Cloned destination repository..."

# Copy and commit build to destination repository
echo "Committing to destination repository..."
rm -rf $DESTINATION_SUBDIR
cp "../$ORIGIN_DIR/build" "./$DESTINATION_SUBDIR" -r

git add .
git commit -m "Update $BUILD_TYPE build: $REACT_APP_VERSION"
git push origin --set-upstream "master"
echo "Committed to destination repository..."

# Build non-SSL repository
echo "Building for non-SSL site..."
cd "../$ORIGIN_DIR"

npm run build$BUILD_NONSSL
cd build
echo "Built for non-SSL site..."

# Copy and FTP transfer build to non-SSL site
echo "Connecting to FTP..."

lftp -u "$FTP_USER","$FTP_PASS" $FTP_HOST <<COMMAND_BLOCK
cd public_html/http
rm -rf "$DESTINATION_SUBDIR"
mirror -R . "$DESTINATION_SUBDIR"

quit
COMMAND_BLOCK

echo "Transferred to FTP..."
