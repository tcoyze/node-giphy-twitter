# node-giphy-twitter

This is a command line tool for translating thoughts to GIFs, and then tweeting them!

## Installation

  `git clone https://github.com/tcoyze/node-giphy-twitter.git`

  `cd node-giphy-twitter`

  `sudo npm link`

## Usage
  From your terminal:

  `gifty --help`
  Returns help menu

### Translate a word or phrase into a gif using Giphy

  `gifty --translate 'american flag'`
  Returns gif ID

### Tweeting with a GIF from the translate process
  `gifty --tweet 'My July 4th!' --id GIF_ID`
  Returns tweet ID

### Tweeting without a GIF
  `gifty --tweet 'Please tweet this for me!'`
  Returns tweet ID
## TODO

  1. *Remove node-twitter-api dependency*

  2. *Reintegrate gif search*

## Author

Tyler Coyner
