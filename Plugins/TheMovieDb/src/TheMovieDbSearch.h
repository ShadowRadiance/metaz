//
//  TheMovieDbSearch.h
//  MetaZ
//
//  Created by Brian Olsen on 30/12/11.
//  Copyright 2011 Maven-Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetaZKit/MetaZKit.h>
#import "../../../Framework/src/SBJson.h"

@interface TheMovieDbSearch : MZOperationsController
{
    NSOperationQueue* queue;
    id provider;
    id<MZSearchProviderDelegate> delegate;
    NSString* baseImageUrl;
    SBJsonParser* _parser;
}
@property(readonly) id provider;
@property(readonly) id<MZSearchProviderDelegate> delegate;

+ (id)searchWithProvider:(id)provider delegate:(id<MZSearchProviderDelegate>)delegate queue:(NSOperationQueue *)queue;
- (id)initWithProvider:(id)provider delegate:(id<MZSearchProviderDelegate>)delegate queue:(NSOperationQueue *)queue;

- (void)queueOperation:(NSOperation *)operation;

- (void)operationsFinished;

- (void)fetchMovieSearch:(NSString *)name;
- (void)fetchMovieSearchCompleted:(id)request;
- (void)fetchMovieSearchFailed:(id)request;

- (void)fetchMovieInfo:(NSNumber *)movieId;
- (void)fetchMovieInfoCompleted:(id)request;
- (void)fetchMovieInfoFailed:(id)request;

@end


/*
 
The new API for TMDB returns solely JSON responses
The old API is no longer available
See http://docs.themoviedb.apiary.io/ for API details
 
Example request: 
    (all prefixed with http://api.themoviedb.org/ )
    (all suffixed with ?api_key=a2d6b9d31ed78237618c953eb2df504d)
    (you can add &append_to_response={related-stuff} to save # of queries
        examples: casts,images
    )

/3/configuration (should be retrieved and cached by application - used for prefixing images with base_url and size
    image urls combine the base+size+path like
        http://d3gtl9l2a4fn1j.cloudfront.net/t/p/w500/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg
)

{
    "images": {
        "base_url": "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/",
        "secure_base_url": "https://d3gtl9l2a4fn1j.cloudfront.net/t/p/",
        "poster_sizes": [
            "w92",
            "w154",
            "w185",
            "w342",
            "w500",
            "original"
        ],
        "backdrop_sizes": [
            "w300",
            "w780",
            "w1280",
            "original"
        ],
        "profile_sizes": [
            "w45",
            "w185",
            "h632",
            "original"
        ],
        "logo_sizes": [
            "w45",
            "w92",
            "w154",
            "w185",
            "w300",
            "w500",
            "original"
        ]
    },
    "change_keys": [
        "adult",
        "also_known_as",
        ...
        "translations"
    ]
}

THIS IS THE COMMON QUERY TO SEARCH

/3/search/movie?query=cgi-escaped
 optionally add the parameters:
    &page={1-n}
    &include_adult={true|false}

{
    "page": 1,
    "results": [
        {
            "adult": false,
            "backdrop_path": "/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg",
            "id": 550,
            "original_title": "Fight Club",
            "release_date": "1999-10-15",
            "poster_path": "/2lECpi35Hnbpa4y46JX0aY3AWTy.jpg",
            "popularity": 61151.745000000003,
            "title": "Fight Club",
            "vote_average": 9.0999999999999996,
            "vote_count": 174
        },
        {
            "adult": false,
            "backdrop_path": "/5Z0FScA1bB6EbdGmZCUBeUk32eV.jpg",
            "id": 14476,
            "original_title": "Clubbed",
            "release_date": "2008-10-02",
            "poster_path": "/bl6PEQtmohEP1zP9srNZY6bXyHg.jpg",
            "popularity": 1.7290000000000001,
            "title": "Clubbed",
            "vote_average": 7.7999999999999998,
            "vote_count": 3
        },
        {
            "adult": false,
            "backdrop_path": "/qw2Qb42xtyE1B449JoTgb1mVCe1.jpg",
            "id": 51021,
            "original_title": "Lure: Teen Fight Club",
            "release_date": "2010-11-16",
            "poster_path": "/aRTX5Y52yGbVL6TGnyI4E8jjtz4.jpg",
            "popularity": 0.26600000000000001,
            "title": "Lure: Teen Fight Club",
            "vote_average": 0.0,
            "vote_count": 0
        },
        {
            "adult": false,
            "backdrop_path": "/tcoAGvTo96R7Y9ZGVCCz7BZvrvb.jpg",
            "id": 104782,
            "original_title": "Florence Fight Club",
            "release_date": "2010-01-01",
            "poster_path": "/eQqqu0srTYcclWqylvgpLyU87hV.jpg",
            "popularity": 0.085000000000000006,
            "title": "Florence Fight Club",
            "vote_average": 0.0,
            "vote_count": 0
        },
        {
            "adult": false,
            "backdrop_path": null,
            "id": 115584,
            "original_title": "Fight Club – The “I am Jack’s Laryngitis” Edit",
            "release_date": null,
            "poster_path": null,
            "popularity": 0.059999999999999998,
            "title": "Fight Club – The “I am Jack’s Laryngitis” Edit",
            "vote_average": 0.0,
            "vote_count": 0
        }
        ],
    "total_pages": 1,
    "total_results": 5
}
 
 
THIS IS THE COMMON QUERY TO GET INDIVIDUAL DETAILS
 
3/movie/{id}
 
Example response:
 
{
   "adult":false,
   "backdrop_path":"/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg",
   "belongs_to_collection":null,
   "budget":63000000,
   "genres":[
       {"id":28,"name":"Action"},
       {"id":18,"name":"Drama"},
       {"id":53,"name":"Thriller"}
   ],
   "homepage":"",
   "id":550,
   "imdb_id":"tt0137523",
   "original_title":"Fight Club",
   "overview":"A ticking-time-bomb insomniac and a slippery soap salesman channel primal male aggression into a shocking new form of therapy. Their concept catches on, with underground \"fight clubs\" forming in every town, until an eccentric gets in the way and ignites an out-of-control spiral toward oblivion.",
   "popularity":19.6243830787667,
   "poster_path":"/2lECpi35Hnbpa4y46JX0aY3AWTy.jpg",
   "production_companies":[
       {"name":"20th Century Fox","id":25},
       {"name":"Fox 2000 Pictures","id":711},
       {"name":"Regency Enterprises","id":508}
   ],
   "production_countries":[
       {"iso_3166_1":"DE","name":"Germany"},
       {"iso_3166_1":"US","name":"United States of America"}
   ],
   "release_date":"1999-10-14",
   "revenue":100853753,
   "runtime":139,
   "spoken_languages":[
       {"iso_639_1":"en","name":"English"}
   ],
   "status":"Released",
   "tagline":"How much can you know about yourself if you've never been in a fight?",
   "title":"Fight Club",
   "vote_average":7.5,
   "vote_count":2622
}
 
 
If you request casts and releases you also get two additional fields:
{
    "adult":false,
    ...
    "vote_average":7.5,
    "vote_count":2625,
    "casts":{
        "cast":[
            {
                "id":819,
                "name":"Edward Norton",
                "character":"The Narrator",
                "order":0,
                "cast_id":4,
                "profile_path":"/iUiePUAQKN4GY6jorH9m23cbVli.jpg"
            },
            ...
            {
                "id":7473,"name":"Rachel Singer","character":"Chloe","order":7,"cast_id":11,"profile_path":null
            }
        ],
        "crew":[
            {"id":7469,"name":"Jim Uhls","department":"Writing","job":"Author","profile_path":null},
            {"id":7474,"name":"Ross Grayson Bell","department":"Production","job":"Producer","profile_path":null},
            {"id":7475,"name":"Ceán Chaffin","department":"Production","job":"Producer","profile_path":null},
            {"id":7477,"name":"John King","department":"Sound","job":"Original Music Composer","profile_path":null},
            {"id":7478,"name":"Michael Simpson","department":"Sound","job":"Original Music Composer","profile_path":null},
            {"id":7479,"name":"Jeff Cronenweth","department":"Camera","job":"Director of Photography","profile_path":null},
            {"id":7480,"name":"James Haygood","department":"Editing","job":"Editor","profile_path":null},
            {"id":7481,"name":"Laray Mayfield","department":"Production","job":"Casting","profile_path":null},
            {"id":1303,"name":"Alex McDowell","department":"Art","job":"Production Design","profile_path":null},
            {"id":7763,"name":"Ren Klyce","department":"Sound","job":"Sound Editor","profile_path":null},
            {"id":7764,"name":"Richard Hymns","department":"Sound","job":"Sound Editor","profile_path":null},
            {"id":7467,"name":"David Fincher","department":"Directing","job":"Director","profile_path":"/dcBHejOsKvzVZVozWJAPzYthb8X.jpg"},
            {"id":7468,"name":"Chuck Palahniuk","department":"Writing","job":"Novel","profile_path":"/8nOJDJ6SqwV2h7PjdLBDTvIxXvx.jpg"}
         ]
    },
    "releases":{
        "countries":[
            {"iso_3166_1":"US","certification":"R","release_date":"1999-10-14"},
            {"iso_3166_1":"DE","certification":"18","release_date":"1999-11-10"},
            {"iso_3166_1":"GB","certification":"18","release_date":"1999-11-12"},
            {"iso_3166_1":"FR","certification":"16","release_date":"1999-11-10"},
            {"iso_3166_1":"TR","certification":"","release_date":"1999-12-10"},
            {"iso_3166_1":"BR","certification":"feibris","release_date":"1999-07-12"},
            {"iso_3166_1":"FI","certification":"K-18","release_date":"1999-11-12"},
            {"iso_3166_1":"BG","certification":"c","release_date":"2012-08-28"},
            {"iso_3166_1":"IT","certification":"VM14","release_date":"1999-10-29"}
        ]
    },
    "images":{
        "backdrops":[
            {"file_path":"/8uO0gUM8aNqYLs1OsTBQiXu0fEv.jpg","width":1280,"height":720,"iso_639_1":"pt","aspect_ratio":1.78,"vote_average":5.51921973608721,"vote_count":20},
            {"file_path":"/hNFMawyNDWZKKHU4GYCBz1krsRM.jpg","width":1280,"height":720,"iso_639_1":"pt","aspect_ratio":1.78,"vote_average":5.44642857142857,"vote_count":17},
            ...
        ],
        "posters":[
            {"file_path":"/2lECpi35Hnbpa4y46JX0aY3AWTy.jpg","width":1000,"height":1500,"iso_639_1":"en","aspect_ratio":0.67,"vote_average":5.45380545380545,"vote_count":54},
            {"file_path":"/eQq7fKMBWK7mM4p7J6R94Hv80ps.jpg","width":930,"height":1240,"iso_639_1":"fr","aspect_ratio":0.75,"vote_average":5.28273809523809,"vote_count":1},
            ...
            {"file_path":"/yShpWHqaZyzY6LgKeGpCl03vJZI.jpg","width":660,"height":826,"iso_639_1":"en","aspect_ratio":0.8,"vote_average":0.0,"vote_count":0},
            {"file_path":"/1FcvRfdWqD3tmWe7dgfXlJBtlTO.jpg","width":400,"height":566,"iso_639_1":"hu","aspect_ratio":0.71,"vote_average":0.0,"vote_count":0},
            {"file_path":"/awYPmDQc8Wga3P2RRutlpPD6PAD.jpg","width":1600,"height":2400,"iso_639_1":"en","aspect_ratio":0.67,"vote_average":0.0,"vote_count":0}
        ]
    }

}

*/