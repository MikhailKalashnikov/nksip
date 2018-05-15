%% -------------------------------------------------------------------
%%
%% Copyright (c) 2015 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc User Response Management Functions
-module(nksip_response).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nksip.hrl").

-export([get_handle/1, srv_id/1, srv_name/1, code/1, body/1, call_id/1]).
-export([meta/2, metas/2, header/2]).
-export([wait_491/0]).

-include("nksip.hrl").
-include("nksip_call.hrl").


%% ===================================================================
%% Public
%% ===================================================================


%%----------------------------------------------------------------
%% @doc Gets response's id
%% @end
%%----------------------------------------------------------------
-spec get_handle( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nksip:handle()}.

get_handle(Term) ->
    case nksip_sipmsg:get_handle(Term) of
        <<"S_", _/binary>> = Handle -> {ok, Handle};
        _ -> error(invalid_response)
    end.


%%----------------------------------------------------------------
%% @doc Gets internal app's id
%% @end
%%----------------------------------------------------------------
-spec srv_id( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nksip:srv_id()}.

srv_id(#sipmsg{class={resp, _, _}, srv_id=SrvId}) ->
    {ok, SrvId};
srv_id(Handle) ->
    case nksip_sipmsg:parse_handle(Handle) of
        {resp, SrvId, _Id, _CallId} -> {ok, SrvId};
        _ -> error(invalid_response)
    end.


%%----------------------------------------------------------------
%% @doc Gets app's name
%% @end
%%----------------------------------------------------------------
-spec srv_name( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nkservice:name()}.

srv_name(Req) -> 
    {ok, SrvId} = srv_id(Req),
    {ok, SrvId:name()}.


%%----------------------------------------------------------------
%% @doc Gets the calls's id of a response id
%% @end
%%----------------------------------------------------------------
-spec call_id( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nksip:call_id()}.

call_id(#sipmsg{class={resp, _, _}, call_id=CallId}) ->
    {ok, CallId};
call_id(Handle) ->
    case nksip_sipmsg:parse_handle(Handle) of
        {resp, _SrvId, _Id, CallId} -> {ok, CallId};
        _ -> error(invalid_response)
    end.


%%----------------------------------------------------------------
%% @doc Gets the response's code
%% @end
%%----------------------------------------------------------------
-spec code( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nksip:sip_code()} 
            | {error, term()}.

code(#sipmsg{class={resp, Code, _Phrase}}) -> 
    {ok, Code};
code(Term) when is_binary(Term) ->
    meta(code, Term).


%%----------------------------------------------------------------
%% @doc Gets the body of the response
%% @end
%%----------------------------------------------------------------
-spec body( Response ) -> Result when 
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, nksip:body()} 
            | {error, term()}.

body(#sipmsg{class={resp, _, _}, body=Body}) -> 
    {ok, Body};
body(Handle) ->
    meta(body, Handle).


%%----------------------------------------------------------------
%% @doc Get a specific metadata
%% @end
%%----------------------------------------------------------------
-spec meta( Feild, Response ) -> Result when 
        Feild       :: nksip_sipmsg:field(),
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, term()} 
            | {error, term()}.

meta(Field, #sipmsg{class={resp, _, _}}=Req) -> 
    {ok, nksip_sipmsg:meta(Field, Req)};
meta(Field, Handle) ->
    nksip_sipmsg:remote_meta(Field, Handle).


%%----------------------------------------------------------------
%% @doc Get a group of specific metadata
%% @end
%%----------------------------------------------------------------
-spec metas( FeildList, Response ) -> Result when 
        FeildList   :: [ nksip_sipmsg:field() ],
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, [{nksip_sipmsg:field(), term()}]} | {error, term()}.

metas(Fields, #sipmsg{class={resp, _, _}}=Req) when is_list(Fields) ->
    {ok, nksip_sipmsg:metas(Fields, Req)};
metas(Fields, Handle) when is_list(Fields) ->
    nksip_sipmsg:remote_metas(Fields, Handle).


%%----------------------------------------------------------------
%% @doc Gets values for a header in a response.
%% @end
%%----------------------------------------------------------------
-spec header( Header, Response ) -> Result when 
        Header      :: string()
            | binary(),
        Response    :: nksip:response()
            | nksip:handle(),
        Result      :: {ok, [binary()]} 
            | {error, term()}.

header(Name, #sipmsg{class={resp, _, _}}=Req) -> 
    {ok, nksip_sipmsg:header(Name, Req)};
header(Name, Handle) when is_binary(Handle) ->
    meta(nklib_util:to_binary(Name), Handle).


%%----------------------------------------------------------------
%% @doc Sleeps a random time between 2.1 and 4 secs. It should be called after
%% receiving a 491 response and before trying the response again.
%% @end
%%----------------------------------------------------------------
-spec wait_491() -> 
    ok.
wait_491() ->
    timer:sleep(10*(rand:uniform(190) + 210)).


