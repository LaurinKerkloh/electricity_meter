# Migration: two VMs → one Proxmox CT (402)

Hand-off notes for whoever continues this (human or agent). Delete this file when
the migration is done.

## Goal
Replace VM 700 `stromzaehler` and VM 701 `electricity-meter` with a single LXC
container, CT 402 `electricity-meter`, which runs:
- Mosquitto (from apt, native);
- this Rails app, native under systemd (no Docker, no Kamal);
- the weekly Nextcloud CSV export as a Solid Queue recurring job, replacing the
  Python script.

The Python parts on VM 700 (`mqtt2db`, `db2cloud.py`, Flask `webpage`) and
MariaDB are dropped. **Keep both VMs running until cutover is done and verified.**

## Rules for working on the homelab
- Host: `ssh zuhause` (Proxmox, root). Outside the LAN, `wg-quick up zuhause` first.
  Docs: `/root/README.md` on the host and in each CT. Read them; keep them updated
  and concise (no dates, no run logs).
- Never change the host without the user's explicit approval. Propose each change
  first; small, single-purpose commands. Read-only is fine.
- **Never look into Nextcloud user files** (`/tank/nextcloud/...`, CT 400), not
  even read-only. Ask the user to check instead.
- Don't print secrets (master key, passwords). Don't commit/push unless asked.

## Current state
### CT 402 (done)
- Debian 13, unprivileged, `nesting=1`, 2 cores, 1 GB RAM, 512 MB swap, 16 GB
  `local-zfs`, `onboot=1`, MAC `BC:24:11:56:CC:E5`.
- **Temporary DHCP IP `192.168.0.223`** (not reserved; may change on reboot,
  check with `ssh zuhause pct exec 402 -- ip -4 -br a`). SSH as root from the Mac
  works (host's authorized keys were copied).
- Timezone UTC (same as both VMs). `unattended-upgrades` enabled (Debian default).
- Packages: `ruby` 3.3.14, `ruby-dev`, `build-essential`, `libyaml-dev`, `git`,
  `sqlite3`, `mosquitto` 2.0.21, `unattended-upgrades`, `curl`.
- Bundler 2.7.2 via `gem install` (matches `BUNDLED WITH`; Debian only has 2.6.7),
  in `/usr/local/bin`. Note: `pct exec` has no `/usr/local/bin` in PATH; use ssh
  or `su - rails`.
- Mosquitto: `/etc/mosquitto/conf.d/default.conf`, same as VM 700: anonymous,
  `listener 1883 0.0.0.0`, `listener 1883 ::`, persistence on. Running, but no
  clients use it yet.
- User `rails` (system user, home `/home/rails`). App checkout:
  `/srv/electricity_meter` (HTTPS clone of the public GitHub repo, owned by
  `rails`), at `bbc89fd`.
- Bundler config (global for `rails`, `/home/rails/.bundle/config`):
  `deployment true`, `without development:test`, `path /home/rails/bundle`.
  `bundle install` done; checkout is clean.
- **New credentials generated on the CT**: `config/master.key` (0600, `rails`) and
  a new `config/credentials.yml.enc` containing only `secret_key_base`. The old
  master key is lost; old credentials (mission_control basic auth) are gone.
  The user saves the new key in their password manager.
- `/jobs` basic auth is off (`config/application.rb`, committed in `bbc89fd`; LAN only).
- `/etc/systemd/system/electricity-meter.service`: enabled and running
  (`User=rails`, `RAILS_ENV=production`, `SOLID_QUEUE_IN_PUMA=1`,
  `bin/thrust bin/rails server`, Thruster `:80` → Puma `:3000`). Logs:
  `journalctl -u electricity-meter`.
- **Cutover step 7.1 done.** VM 701's app container is stopped (restart policy
  `unless-stopped`, so it stays stopped; `kamal-proxy` still runs, `.123` gives 502). Its
  `production.sqlite3` (max id 8111076, 2 devices, `disable_switching` already
  `false`) is now the CT's `storage/production.sqlite3`; the original is untouched in
  VM 701's volume. Queue/cache/cable DBs on the CT are fresh. The CT app switches the
  devices now. Readings between ~21:53 and 21:57 UTC on Nov 23 are missing in SQLite;
  the MariaDB merge (7.2) fills them.
- `MqttListener` reconnects every 5 s after a broker outage (`c0e6424`, deployed and
  tested against a Mosquitto restart). Messages published while it isn't subscribed
  are lost (QoS 0, clean session); accepted.
- In progress: Ruby/gem upgrade (uncommitted in the working tree, not yet on the CT).
  Ruby stays on Debian's apt Ruby (3.3.14 on the CT; `.ruby-version` must match it;
  on the Mac via mise). All gems updated, Rails 8.1 with `load_defaults 8.1`;
  `tailwindcss-rails` stays on 3.x (v4 is a CSS migration). Adds the optional Solid
  Queue batches migration in `db/queue_migrate/`. Deploy on the CT: pull,
  `bundle install`, `assets:precompile db:migrate`, restart.
- Dead route `resources :trigger_points` (no controller): 404 on Rails 8.0, 500 on 8.1.
  Left in place; the user decides.
- The app exits with status 255 on SIGTERM (also in Docker), so `systemctl stop`
  leaves the unit `failed`. Harmless.
- Known: `/` returns 500 on an empty DB (`overview/show.html.erb:2`, `@house` nil)
  until the first reading of each meter exists.

### Not started
- `bin/deploy`.
- Data merge, cutover, READMEs.
- Nextcloud export job (do this **after** the app runs on the CT).

## Remaining steps
Steps 1–5 are done (step 4 skipped, see "Current state").

1. **User** commits and pushes the repo changes. On the CT:
   `git checkout -- config/credentials.yml.enc && git pull` (as `rails`). The pulled
   file is identical to the one generated there, so `master.key` still matches.
   Verify: `RAILS_ENV=production bin/rails runner 'p MissionControl::Jobs.http_basic_auth_enabled'` → `false`.
2. **systemd unit** `electricity-meter.service`: `User=rails`,
   `WorkingDirectory=/srv/electricity_meter`, `RAILS_ENV=production`,
   `SOLID_QUEUE_IN_PUMA=1`, `ExecStart=bin/thrust bin/rails server` (Thruster on
   `:80`, Puma behind it). Binding `:80` as non-root needs
   `AmbientCapabilities=CAP_NET_BIND_SERVICE`. `Restart=always`, enable on boot.
   The master key is read from `config/master.key` (gitignored).
3. As `rails`: `RAILS_ENV=production bin/rails db:prepare assets:precompile`.
4. **Before the first start, disable switching in the new DB**
   (`SwitchingConfiguration.load.update!(disable_switching: true)`), otherwise both
   the old and the new app toggle the devices. The MQTT listener connects to the
   hardcoded `192.168.0.122` (`config/initializers/mqtt_listener.rb`). That is
   VM 700's broker during the parallel run and the CT itself after cutover, so no
   code change is needed.
5. Start and check: web UI on `http://192.168.0.223`, readings arrive, `/jobs` works.
6. **`bin/deploy`: deferred by the user ("maybe later").** Until then, deploy by
   hand: ssh to the CT and, as `rails`,
   `git pull --ff-only && bundle install && RAILS_ENV=production bin/rails assets:precompile db:migrate`,
   then `systemctl restart electricity-meter`. **Keep the Kamal leftovers until
   cutover** (`config/deploy.yml`, `.kamal/`, `bin/kamal`, `Dockerfile`, `kamal`
   gem); after cutover, ask the user before removing them.
7. **Cutover** (each step confirmed with the user):
   1. On VM 701, stop the app container. Copy `production.sqlite3` with
      `sqlite3 ... ".backup ..."` from the Docker volume `electricity_meter_storage`
      (`docker volume inspect -f '{{.Mountpoint}}' electricity_meter_storage`; the
      container has `sqlite3`, the VM host doesn't). Copy it to the CT, replacing
      the test DB. It holds `devices` (2), `switching_configurations` (1) and the
      readings. Then set `disable_switching` back to its old value (`false`).
   2. On VM 700, stop `mqtt2db`. Export `meter_readings` and merge it into SQLite
      (see "Data" below).
   3. Shut down VM 700. Set CT 402's `net0` `hwaddr` to VM 700's MAC
      `6E:39:7A:0A:4B:BB`, so the router's DHCP reservation hands it
      **`192.168.0.122`**. Both meters (Tasmota `.120` Haus, `.121` Solar) publish
      to `192.168.0.122` by IP, so nothing changes on them. The web UI moves from
      `.123` to `.122`. Optionally add a second NIC with VM 701's MAC
      `FE:4E:64:58:94:F1` to keep `.123`. Ask the user.
   4. Shut down VM 701. Verify that readings arrive, switching works, and the web UI
      loads. Keep the VMs (stopped) for a while; delete them only on the user's go.
   5. Update the host's `/root/README.md` (guest table: remove VM 700/701, add
      CT 402) and write CT 402's `/root/README.md` (what runs, paths, deploy,
      Mosquitto config).
8. **Nextcloud export job** (app change, after cutover): see "Export spec".
   Credentials: user `stromzaehler` plus an app password in Rails credentials
   (`nextcloud.password`; the user adds it with `bin/rails credentials:edit`
   locally and the new master key). Upload with a WebDAV `PUT` via `Net::HTTP`
   (no new gem). Schedule it in `config/recurring.yml` **with an explicit `UTC`**:
  since Solid Queue 1.5, schedules without a zone use `config.time_zone`
  (Europe/Berlin).

## Data
| | MariaDB on VM 700 (`electricity_meter.meter_readings`) | Rails SQLite on VM 701 (`electricity_meter_readings`) |
|---|---|---|
| First real reading | 2023-08-20 | 2025-05-17 |
| Rows (Nov 2026) | 19.56 M | 8.09 M (1.1 GB file) |
| Bogus `1970-01-01` rows | 34 | 8 |

Both are written live, but each has gaps the other fills (SQLite is missing much
of Feb/Mar 2026; MariaDB part of Oct 2025). **Merge MariaDB into SQLite**:
- Columns: `electricity_meter_name` (`Haus`/`Solar`) → `meter` (`house`/`solar`),
  plus `reading`, `current_power`, `time`. Set `created_at`/`updated_at` = `time`.
- `time` is the raw Tasmota `Time` (local time, no zone) in both DBs and matches
  between them. Rails parses it as UTC (`MqttMessageHandler`). The notes used to
  assume local time, but a CT reading stored at 11:57 UTC had `time` 11:57, so the
  meters probably send UTC; verify against MariaDB. Either way, keep the values
  identical during the migration.
- `MqttMessageHandler` stores `time` without a fraction (`2026-11-23 22:10:50`).
- Unique index `(time, meter)` → `INSERT OR IGNORE`. First check that the text
  format of `time` in SQLite (e.g. `2026-11-22 10:24:08`, with or without a
  fraction) matches what you insert, otherwise dedup won't work.
- Insert with plain SQL, not ActiveRecord: the `after_commit` callback on
  `ElectricityMeterReading` would switch devices.
- Skip the bogus pre-2000 rows.
- Expected result: roughly 2.5–3 GB SQLite.
- In MariaDB, ids are in insertion order. Use `ORDER BY id` when exporting so the
  `id` order stays meaningful for the export job.

## Export spec (must match the old `db2cloud.py` exactly)
The old script: `/stromzaehler/db2cloud.py` on VM 700, cron `0 6 * * 1` (UTC).
- WebDAV base: `https://cloud.kerk-loh.de/remote.php/dav/files/stromzaehler/`,
  user `stromzaehler`.
- One file per meter, `Solar` first, then `Haus`:
  `/Stromzaehler/<Y><W><Meter>.csv`.
  - `d = now - 7 days`; `<Y>` = **calendar** year of `d` (not the ISO year);
    `<W>` = ISO week of `d`, **not zero-padded** (e.g. `20265Haus.csv`).
- Rows: all readings of that meter in the ISO week (Mon–Sun) containing `d`
  (MariaDB `YEARWEEK(time, 3)`), in insertion order (`ORDER BY id`).
- Line format, no header, `\n` line ending, trailing newline:
  `31215.7441,484,"2026-11-09 00:00:05"`
  - `reading`: always 4 decimals, unquoted (watch out: `BigDecimal#to_s` drops
    trailing zeros);
  - `current_power`: integer, unquoted;
  - `time`: `YYYY-MM-DD HH:MM:SS` in double quotes, the raw stored value (no zone
    conversion).
- Existing remote files are overwritten. A week with no data → upload an empty file.
- Schedule: Mondays 06:00 UTC.

## Reference
- VM 700 `stromzaehler` `192.168.0.122` (root ssh): Mosquitto, MariaDB,
  `mqtt2db.service` (`/home/mqtt2db/main.py`), cron `db2cloud.py`,
  `webpage.service` (Flask) behind nginx `:80`.
- VM 701 `electricity-meter` `192.168.0.123` (root ssh): Docker, kamal-proxy, this
  app, Kamal env in `/root/.kamal/apps/electricity_meter/env/roles/web.env`.
- Tasmota meters: `.120` Haus (15.5.0, ottelo.jimdofree.com SML build),
  `.121` Solar (11.1.0, web password set). The release build has no SML. Always
  use a build with `USE_SCRIPT` + `USE_SML_M`.
- Lightmanager (scenes, marker state): `http://192.168.0.62` (`app/services/light_manager.rb`).
