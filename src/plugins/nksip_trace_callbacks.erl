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

%% @doc NkSIP SIP Trace Registrar Plugin Callbacks
-module(nksip_trace_callbacks).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-include("nksip.hrl").

-export([nksip_connection_sent/2, nksip_connection_recv/2]).



%% ===================================================================
%% SIP Core
%% ===================================================================


%% @doc Called when a new message has been sent
-spec nksip_connection_sent(nksip:request()|nksip:response(), binary()) ->
    continue.

nksip_connection_sent(SipMsg, Packet) ->
    #sipmsg{srv_id=SrvId, call_id=CallId, nkport=NkPort} = SipMsg,
    nksip_trace:sipmsg(SrvId, CallId, <<"TO">>, NkPort, Packet),
    continue.


%% @doc Called when a new message has been received and parsed
-spec nksip_connection_recv(nksip:request()|nksip:response(), binary()) ->
    continue.

nksip_connection_recv(SipMsg, Packet) ->
    #sipmsg{srv_id=SrvId, call_id=CallId, nkport=NkPort} = SipMsg,
    nksip_trace:sipmsg(SrvId, CallId, <<"FROM">>, NkPort, Packet),
    continue.

