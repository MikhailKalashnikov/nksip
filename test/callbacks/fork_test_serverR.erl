%% -------------------------------------------------------------------
%%
%% fork_test: Forking Proxy Suite Test
%%
%% Copyright (c) 2013 Carlos Gonzalez Florido.  All Rights Reserved.
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

-module(fork_test_serverR).

-include_lib("nkserver/include/nkserver_module.hrl").

-export([srv_init/2, sip_route/5]).

srv_init(_Package, State) ->
    ok = nkserver:put(?MODULE, domains, [<<"nksip">>, <<"127.0.0.1">>, <<"[::1]">>]),
    {ok, State}.


sip_route(Scheme, User, Domain, Req, _Call) ->
    % Route for fork_test_serverR in fork test
    % Adds x-nk-id header, and Record-Route if Nk-Rr is true
    % If nk-redirect will follow redirects
    Opts = lists:flatten([
        {insert, "x-nk-id", ?MODULE},
        case nksip_request:header(<<"x-nk-rr">>, Req) of
            {ok, [<<"true">>]} -> record_route;
            {ok, _} -> []
        end,
        case nksip_request:header(<<"x-nk-redirect">>, Req) of
            {ok, [<<"true">>]} -> follow_redirects;
            {ok, _} -> []
        end
    ]),
    Domains = nkserver:get(?MODULE, domains),
    case lists:member(Domain, Domains) of
        true when User =:= <<>> ->
            process;
        true when Domain =:= <<"nksip">> ->
            case nksip_registrar:qfind(?MODULE, Scheme, User, Domain) of
                [] -> {reply, temporarily_unavailable};
                UriList -> {proxy, UriList, Opts}
            end;
        true ->
            {proxy, ruri, Opts};
        false ->
            {reply, forbidden}
    end.
