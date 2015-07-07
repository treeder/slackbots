# Uptime bot

Uptime bot uses pingdom checks to determing the total uptime for all services. Uptime is an aggregate, not an average.

Pingdom requires your username, password, and api token in order to use their api. Due to the amount of redundant checks we have, this version requires you to supply the ids of the checks you want to use. In our specific case, we have three different sets: mq checks, worker checks, and other services.
