Kind of like /giphy, but you can set your own keywords and responses. See commands.json to change it. 

If you want your own commands.json, change guppy.rb to use the file loading, by default it reads it
directly from this repo on Github. 

## Building

```sh
docker build -t treeder/guppy:`cat VERSION` .
```

Test it with:

```sh
docker run --rm -e "PAYLOAD=`cat slack.payload`" treeder/guppy:`cat VERSION`
```
