New goal: search through tracks submitted in the last day, per genre, and find the 'hottest' ones (based on an arbitrary definition of hotness).  Put these in appropriate playlists and reshare the best one to the feed.

`be ruby main.rb`

**NOTE:**  Soundcloud REST API does not behave as you'd expect:  

- Genre parameter is almost entirely useless ('q' usually works well for genre filtering)
- Variable number of returns
- Inexplicable 400 errors unreliably (i.e. non-idempotent), for example when requested track limit provided is larger than 200
