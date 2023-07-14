# Hosting PLAN on a server

## Steps to get a pico engine running under TLS
1. Choose a domain name (check: PLAN.picolabs.io)
2. Choose a linux server host (check: AWS; elastic IP address configured)
3. Connect the domain name to the server IP address (check)
4. Install `node` and `npm` (check: used `nvm` to install `node` version 16)
5. Install the pico engine (check: used `npm install -g pico-engine`)
6. Using `nginx` create a reverse proxy (from the default (`80`)) to `localhost:3000` (check)
7. Obtain a certificate for your domain name (check: we used `certbot --nginx`)
8. Start your engine (check: we used `PICO_ENGINE_BASE_URL=https://… forever start .nvm/…/pico-engine`)

## Steps to get the affiliate code running
1. Locate the pico engine `public` folder (check: it was deeply nested in the `~/.nvm/` folder)
2. Place two of the pages from the `docs` folder therein: `plan.html` and `about.html` (check)
3. In the `public` folder, copy `index.html` to someplace of your choice, then copy `plan.html` to be `index.html` (check)
4. In the developer UI of the pico engine, create a child pico named "Affiliates" (check)
5. Install in it the `io.picolabs.plan.affiliates` ruleset (check)
6. Add a new channel (tagged `plan` `affiliates`) allowing all events and queries for that ruleset (check)
7. Modify the `action` attribute of the `form` tag in `plan.html` to replace DOMAIN with our domain
8. Modify the `action` attribute of the `form` tag in `plan.html` (aka `index.html`) to replace ECI with that channel's ID (check)

## Get some friends to help work out bugs/friction in the joining process
(check)
