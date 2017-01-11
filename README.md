New goal: search through tracks submitted in the last day, per genre, and find the 'hottest' ones (based on an arbitrary definition of hotness).  Put these in appropriate playlists and reshare the best one to the feed.

Currently the good stuff is in lib, `main.rb` will be mostly deprecated as it is yucky.

`be ruby main.rb`

*Note this is an exercise in test-driving library/toolkit level code, and so the development style and testing strategies are somewhat experimental and perhaps more thorough than strictly necessary.*

*Note about resharing: this isn't an officially supported action, and so is a little hacky

http://stackoverflow.com/questions/19266083/reposting-a-track-via-the-soundcloud-api

http://stackoverflow.com/questions/14914059/soundcloud-api-extracting-tracks-reposted-by-a-user*

## TODOS
- Pull down and update Uta's playlists in a service object / ORM fashion
- Better organization configuration and constants (e.g. MAX_REQUEST_PAGE_SIZE)
- Resolve issue with apparently mis-documented create_at argument filters (soundcloud documentation specifies a filter argument as an object with specifically formatted dates, created_at[from] and created_at[to], but these seem not to work as opposed to the older and now undocumented string argument 'last_week'[???])
- API integration and contract testing (maybe VCR)
- Decouple logic pertinent to searching and sorting, e.g. a strategy class
- Alternative strategies for song selection, e.g. collaborative filtering
