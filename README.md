New goal: search through tracks submitted in the last day, per genre, and find the 'hottest' ones (based on an arbitrary definition of hotness).  Put these in appropriate playlists and reshare the best one to the feed.

Currently the good stuff is in lib, `main.rb` will be deprecated as it is yucky.

`be ruby main.rb`

## TODOS
- Better organization configuration and constants (e.g. MAX_REQUEST_PAGE_SIZE)
- Resolve issue with apparently mis-documented create_at argument filters (soundcloud documentation specifies a filter argument as an object with specifically formatted dates, created_at[from] and created_at[to], but these seem not to work as opposed to the older and now undocumented string argument 'last_week'[???]) 
- API integration and contract testing (maybe VCR)
- Alternative strategies for song selection, e.g. collaborative filtering
