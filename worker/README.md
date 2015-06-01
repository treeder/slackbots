Runs an IronWorker, returns results to Slack. 

Example: 

```
/worker IRON_PROJECT_ID IRON_TOKEN MY_WORKER_NAME
```

## Testing

This one requires a change to the `slack.payload` file in this directory to include your [Iron.io](http://www.iron.io) 
credentials. Replace `IRON_PROJECT_ID` and `IRON_TOKEN` to your Iron credentials then test with the Docker run command. 

