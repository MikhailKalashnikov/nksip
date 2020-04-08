%% -------------------------------------------------------------------
%%
%% Copyright (c) 2019 Carlos Gonzalez Florido.  All Rights Reserved.
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

%% @doc NkSIP GRUU Plugin Callbacks
-module(nksip_outbound_callbacks).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include_lib("nklib/include/nklib.hrl").
-include("nksip.hrl").
-include("nksip_registrar.hrl").

-export([nksip_uac_proxy_opts/2, nksip_transport_uac_headers/6]).
-export([nksip_registrar_request_opts/2, nksip_registrar_request_reply/3,
	     nksip_registrar_get_index/2]).


%% ===================================================================
%% SIP Core
%% ===================================================================

%% @doc Called to add options for proxy UAC processing
-spec nksip_uac_proxy_opts(nksip:request(), nksip:optslist()) ->
    {continue, list()} | {reply, nksip:sipreply()}.

nksip_uac_proxy_opts(Req, ReqOpts) ->
    case nksip_outbound:proxy_opts(Req, ReqOpts) of
        {ok, ProxyOpts} -> 
            {continue, [Req, ProxyOpts]};
        {error, OutError} -> 
            {reply, OutError}
    end.


%% @doc Called when preparing the request for sending
nksip_transport_uac_headers(Req, Opts, Scheme, Transp, Host, Port) ->
    Req2 = nksip_outbound:add_headers(Req, Opts, Scheme, Transp, Host, Port),
    {ok, Req2}.


%% @private
nksip_registrar_request_opts(Req, Opts) ->
	nksip_outbound:check_several_reg_id(Req#sipmsg.contacts),
    {Req2, Opts2} = case nksip_outbound:registrar(Req) of
        {true, Req1} ->
            {Req1, [{outbound, true}|Opts]};
        {false, Req1} ->
            {Req1, [{outbound, false}|Opts]};
        no_outbound ->
            {Req, Opts};
        {error, OutError} ->
            throw(OutError)
    end,
    {continue, [Req2, Opts2]}.


%% @private
nksip_registrar_request_reply(Reply, Regs, Opts) ->
	Reply1 = case Reply of
		{ok, ReplyOpts} ->
	        case 
	            lists:member({outbound, true}, Opts) andalso
	            [true || #reg_contact{index={ob, _, _}} <- Regs] 
	        of
	            [_|_] ->
                    {ok, [{require, <<"outbound">>}|ReplyOpts]};
	            _ ->
                    {ok, ReplyOpts}
	        end;
	    Other ->
	    	Other
	end,
	{continue, [Reply1, Regs, Opts]}.


%% @private
nksip_registrar_get_index(#uri{ext_opts=ExtOpts}=Contact, Opts) ->
    InstId = case nklib_util:get_value(<<"+sip.instance">>, ExtOpts) of
        undefined ->
            <<>>;
        Inst0 ->
            nklib_util:hash(Inst0)
    end,
    Outbound = nklib_util:get_value(outbound, Opts),
    RegId = case nklib_util:get_value(<<"reg-id">>, ExtOpts) of
        undefined ->
            <<>>;
        _ when Outbound == undefined ->
            <<>>;
        _ when Outbound == false ->
            throw(first_hop_lacks_outbound);
        _ when InstId == <<>> ->
            <<>>;
        RegId0 ->
            RegId0
    end,
    case RegId of
        <<>> ->
            {continue, [Contact, Opts]};
        _ ->
            {ok, {ob, InstId, RegId}}
    end.