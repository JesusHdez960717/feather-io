# The console

A tour of the Feather IO web console: each screen, its URL and what it does. The images come from
the design of the console ([`design/`](design/README.md)), in Spanish, one of its two languages
(English and Spanish, from the selector in the rail).

URLs are relative to where the console is served (`http://localhost:8081` by default). The console
uses hash URLs, so the screen and its state go after `#`:
`http://localhost:8081/#/browser?bucket=photos`.
Screens whose state is worth sharing keep it in the URL, so a link opens the same bucket, folder,
view or tab.

## Configuration and login

![Login](design/screens/02-login.png)

**URL:** `/#/login` (with `?from=` the page asked for before logging in, opened again afterwards)

The console only needs to know where the service is. It reads it from `window.env`, in `web/env.js`
locally or from the environment of its Docker image:

| Variable       | Default                 | What it is                                                                                                                                        |
|----------------|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `SERVICE_URL`  | `http://localhost:8080` | The service **as the browser sees it**: the console calls it from the browser, not from its container. Behind a domain or a proxy, its public URL |
| `ADMIN_PREFIX` | `_admin`                | Prefix of the admin API; it must match the service's                                                                                              |

```bash
docker run -p 8081:80 -e SERVICE_URL=https://s3.example.com -e ADMIN_PREFIX=_admin feather-io-console
```

You log in with the **root key** of the service: *Access key* is its `FEATHER_ACCESS` and *Secret
key* its `FEATHER_SECRET`. Access keys created in the console are for S3 clients and can't log in.
The service answers with a token valid for 12 hours, which the console keeps across reloads; the
keys typed are never stored by the console (the browser's password manager may offer to save them).
After 10 wrong attempts in a row the service locks the IP for 15 minutes.

While it starts, the console shows a splash:

![Splash](design/screens/01-splash.png)

## Navigation

![Navigation rail](design/screens/31-rail-expanded.png)

The rail on the left opens the three sections: **Browser** (`/#/browser`), **Buckets**
(`/#/buckets`) and **Access keys** (`/#/keys`). At its foot: the **transfers** indicator (with
the progress of the uploads and downloads in course), the **language** and **log out**. The menu
button expands it to show the names.

## Browser: the buckets

![Buckets, list view](design/screens/03-buckets-list.png)

**URL:** `/#/browser` (`?view_type=list` or `grid`)

The start page. It shows the totals (buckets, objects, storage) and the list of buckets, which can
be searched and seen as a list or as cards. Opening a bucket enters it.

![Buckets, grid view](design/screens/04-buckets-grid.png)

The menu of each bucket opens its settings (in *Buckets*), edits it or deletes it.

**Create bucket** opens a drawer: the name is checked as you type against the S3 rules (3 to 63
characters, lowercase letters, numbers and hyphens, no hyphen at the ends), with an optional
description and a color for the console.

|                                                       |                                                               |
|-------------------------------------------------------|---------------------------------------------------------------|
| ![Create bucket](design/screens/05-create-bucket.png) | ![Validation](design/screens/06-create-bucket-validation.png) |
| ![Custom color](design/screens/07-bucket-color.png)   |                                                               |

## Browser: inside a bucket

![Objects, list view](design/screens/08-objects-list.png)

**URL:** `/#/browser?bucket=<bucket>&folder=<folder>&view_type=list` (`folder` without a trailing
`/`, e.g. `photos/2026`; without it, the root of the bucket)

The objects and folders of the current folder, with the path as breadcrumbs, back and forward,
refresh, **New folder** and **Upload**. Objects are paged (25, 50, 75 or 100 per page); the search
and the filters look at the pages already loaded.

![Objects, grid view](design/screens/09-objects-grid.png)

The menu of an object opens its details, shares it, renames it, moves it, downloads it or deletes
it:

![Object menu](design/screens/10-objects-menu.png)

Selecting several objects enables downloading them (as a zip), moving them or deleting them:

![Several selected](design/screens/11-objects-selected.png)

|                                                   |                                                                                             |
|---------------------------------------------------|---------------------------------------------------------------------------------------------|
| ![Filters](design/screens/12-objects-filters.png) | ![Drop to upload](design/screens/13-objects-drop.png)                                       |
| **Filters** by type, size and date                | **Drag & drop** files onto the list to upload them                                          |
| ![Delete](design/screens/14-delete-objects.png)   | ![Details](design/screens/15-object-details.png)                                            |
| **Delete** asks for confirmation                  | **Details**: preview, key, type, size, date and URL                                         |
| ![New folder](design/screens/16-new-folder.png)   | ![Rename](design/screens/17-rename.png)                                                     |
| **New folder**                                    | **Rename** (copy and delete, like S3)                                                       |
| ![Move](design/screens/18-move.png)               | ![Share](design/screens/19-share-link.png)                                                  |
| **Move** to another folder of the bucket          | **Share link**: a presigned URL for 1 hour, 1 day or 7 days, which works without logging in |

### Transfers

![Transfers](design/screens/20-transfers.png)

Uploads and downloads run in the background: they keep going while you move between folders,
buckets and sections, 2 uploads and 2 downloads at a time. The indicator in the rail shows the
overall progress; its panel lists each file with its progress, and lets you cancel, retry or clear
the finished ones. Files over 16 MiB are uploaded in parts. Closing the tab with transfers running
asks first.

## Buckets

![Bucket, general tab](design/screens/21-bucket-general.png)

**URL:** `/#/buckets?bucket=<bucket>&tab=general` (`tab`: `general`, `access` or `danger`)

The list of buckets on the left and the details of the selected one: name, S3 path, description,
color, number of objects, size and dates. **Open in browser** enters it; **Edit** changes its
description and color.

![Edit bucket](design/screens/26-edit-bucket.png)

### Anonymous access

![Anonymous access rules](design/screens/22-bucket-access.png)

Rules that open part of a bucket to requests without credentials: read only (list and download),
write only (upload and delete) or both. A rule without `*` is a prefix (`public/`, everything
below it); with `*` the whole key must match the pattern (`photos/*.jpg`).

![Add a rule](design/screens/23-bucket-add-rule.png)

### Danger zone

![Danger zone](design/screens/24-bucket-danger.png)

**Empty** deletes every object and keeps the bucket, its settings and its rules; it asks you to type
the name of the bucket. **Delete** removes the bucket with its description, color and rules; as in
S3, only when it is empty.

![Empty a bucket](design/screens/25-bucket-empty-confirm.png)

## Access keys

![Access keys](design/screens/27-access-keys.png)

**URL:** `/#/keys`

The keys S3 clients (AWS CLI, rclone, SDKs) sign with, besides the root key of the service: their
id, permissions, last use and state (active, disabled, expired). The root key is listed first and
can't be changed here. Each key's menu edits its permissions, disables or enables it, regenerates
its secret or
deletes it.

![Menu of a key](design/screens/28-access-key-menu.png)

A key gets a name, an optional expiry, and either one level on every bucket (current and future,
and only then it can create and delete buckets) or a level per bucket: read, write or both.

![Create a key](design/screens/29-access-key-create.png)

The secret is shown **once**, when the key is created or its secret regenerated; the dialog can't be
closed until you confirm you saved it (it can also be downloaded as a `.csv`).

![Key created](design/screens/30-access-key-created.png)
