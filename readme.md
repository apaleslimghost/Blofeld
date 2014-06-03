# Blofeld

Setup and sync an S3 bucket for website serving

## Installation

```
npm install -g blofeld
```

Yes, I'm using npm to distribute a shell script.

![Deal with it.](https://dl.dropboxusercontent.com/u/3723930/deal_with_it.gif)

## Usage

```sh
blofeld -t target_bucket -f folder [-s short_expiry_files] [-g gzipped_files]
```

Let's say you have a folder, `dist`, that you want to serve from the S3 bucket `my-awesome-website`. That's easy, it

```sh
blofeld -t my-awesome-website -f dist
```

This creates the bucket, tells S3 to serve it as a website, and syncs `dist` to it. Nice. 

By default, Blofeld sets the expiry to one year. You probably want say HTML files to expire quickly, so list them on the `-s` option:

```sh
blofeld -t my-awesome-website -f dist -s "dist/index.html dist/faq.html"
```

And now they have five-minute expiry. Ok, so S3 doesn't support dynamic GZIP, and maybe you'd like to compress your Javascript files. Add them to the `-g` option (NB Blofeld doesn't gzip things himself yet):

```sh
blofeld -t my-awesome-website -f dist -g "dist/app.js"
```

More configuration coming soon.

## Prerequisites

Blofeld requires the AWS command line tool, which can be installed via Pip:

```sh
pip install awscli
```

Run `aws configure` to set up your credentials.

## Licence

MIT. &copy; MMXIV Matt Brennan
