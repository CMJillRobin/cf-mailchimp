/*
* ColdFusion MailChimp API 3.0 wrapper
* v1.1.1
* https://github.com/kevindb/cf-mailchimp
*
* ColdFusion wrapper for the MailChimp 3.0 API
*
* Copyright 2015 Kevin Morris
*
* This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either version 2.1 of the License, or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
*/


component displayname="MailChimp" {
	variables.apiHost = "https://us1.api.mailchimp.com/3.0/";
	variables.apiKey = "";
	variables.debug = false;

	public mailchimp function init (
		required string apiKey,
				 string apiHost = "",
				 boolean debug = false,
				 string jsonUtil = "JSONUtil"
	) {
		if (len(arguments.apiKey) > 0) {
			variables.apiKey = arguments.apiKey;

			// Allow apiHost to be set manually
			if (len(arguments.apiHost) > 0) {
				variables.apiHost = arguments.apiHost;

			// Get datacenter from API key
			} else {
				dc = listLast(variables.apiKey, "-");
				variables.apiHost = replace(variables.apiHost, "us1", dc);
			}

			variables.debug = arguments.debug;

		} else {
			throw(message="apiKey was not set");
		}

		try {
			variables.JSONUtil = new "#arguments.jsonUtil#"();

		} catch(any error) {
			if (variables.debug) { writeDump(error); }
		}

		return this;
	}

	// MailChimp List calls
	// http://developer.mailchimp.com/documentation/mailchimp/reference/lists/
	public function getLists(
		struct params = {}
	) {
		return get(
			endpoint = "lists",
			params = arguments.params
		);
	}

	public function getList(
		required string listId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId,
			params = arguments.params
		);
	}


	// MailChimp Member calls
	// http://developer.mailchimp.com/documentation/mailchimp/reference/lists/members/

	// Retrieves a list of all members of the specified list
	public function getListMembers (
		required string listId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId & "/members",
			params = arguments.params
		);
	}

	// Retrieves details on a single member of the specified list
	public function getListMember (
		required string listId,
		required string email,
				 struct params = {}
	) {
		memberId = getMemberIdFromEmail(arguments.email);

		return get(
			endpoint = "lists/" & arguments.listId & "/members/" & memberId,
			params = arguments.params
		);
	}

	// Uses a batch operation to add or update multiple members of the specified list
	public function putListMembers (
		required string listId,
		required array members,
				 struct params = {}
	) {
		response = {};
		operations = [];

		try {
			for (data in arguments.members) {
				memberId = getMemberIdFromEmail(data.email_address);

				operations.append({
					method = "PUT",
					path = "/lists/" & arguments.listId & "/members/" & memberId,
					body = variables.serializeJson(data)
				});
			}

			response = batch(
				operations = operations,
				params = arguments.params
			);

		} catch(any error) {
			if (variables.debug) { writeDump(error); }
		}

		return response;
	}

	// Adds or updates a single member to the specified list
	public function putListMember (
		required string listId,
		required struct data,
				 struct params = {}
	) {
		response = {};

		try {
			memberId = getMemberIdFromEmail(arguments.data.email_address);

			response = put(
				endpoint = "lists/" & arguments.listId & "/members/" & memberId,
				data = arguments.data,
				params = arguments.params
			);


		} catch(any error) {
			if (variables.debug) { writeDump(error); }
		}

		return response;
	}

	// Generates the member ID, the MD5 hash of the email address
	// http://developer.mailchimp.com/documentation/mailchimp/guides/manage-subscribers-with-the-mailchimp-api/
	public string function getMemberIdFromEmail (
		required string email
	) {
		return lcase(hash(lcase(trim(arguments.email)), "MD5"));
	}


	// MailChimp Interest Group calls
	// https://developer.mailchimp.com/documentation/mailchimp/reference/lists/interest-categories/
	// Retrieves a list of all interest groups of the specified list
	public function getGroups (
		required string listId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId & "/interest-categories",
			params = arguments.params
		);
	}

	// Retrieves details on a single interest group of the specified list
	public function getGroup (
		required string listId,
		required string groupId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId & "/interest-categories/" & arguments.groupId,
			params = arguments.params
		);
	}

	// Retrieves a list of all interests in the specified group
	public function getInterests (
		required string listId,
		required string groupId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId & "/interest-categories/" & arguments.groupId & "/interests",
			params = arguments.params
		);
	}

	// Retrieves details on a single interest in the specified group
	public function getInterest (
		required string listId,
		required string groupId,
		required string interestId,
				 struct params = {}
	) {
		return get(
			endpoint = "lists/" & arguments.listId & "/interest-categories/" & arguments.groupId & "/interests/" & arguments.interestId,
			params = arguments.params
		);
	}


	// Performs a generic HTTP GET operation
	private struct function get (
		required string endpoint,
				 struct params = {}
	) {
		local.url = variables.apiHost & arguments.endpoint & structToQueryString(arguments.params);

		if (variables.debug) { writeOutput("HTTP GET: " & local.url & "<br>"); }

		httpService = new http(url=local.url, method="get", password=variables.apiKey, username="");
		httpContent = httpService.send().getPrefix().fileContent;
		responseJson = variables.parseJson(httpContent);

		return responseJson;
	}

	// Performs a generic HTTP PUT operation
	private function put (
		required string endpoint,
				 struct data,
				 struct params = {}
	) {
		local.url = variables.apiHost & arguments.endpoint & structToQueryString(arguments.params);

		if (variables.debug) {
			writeOutput("HTTP PUT: " & local.url & "<br>");
			writeDump(variables.serializeJson(arguments.data));
		}

		httpService = new http(url=local.url, method="put", password=variables.apiKey, username="");
		httpService.addParam(type="body", value=variables.serializeJson(arguments.data));
		httpService = httpService.send();

		if (variables.debug) { writeDump(httpService); }

		httpContent = httpService.getPrefix().fileContent;
		responseJson = variables.parseJson(httpContent);

		return responseJson;
	}

	// Performs a MailChimp's HTTP POST batch operation
	private function batch (
		required array operations,
				 struct params = {}
	) {
		local.url = variables.apiHost & "batches" & structToQueryString(arguments.params);
		data = { operations = arguments.operations };

		if (variables.debug) {
			writeOutput("HTTP POST: " & local.url & "<br>");
			writeDump(variables.serializeJson(arguments.data));
		}

		httpService = new http(url=local.url, method="post", password=variables.apiKey, username="");
		httpService.addParam(type="body", value=variables.serializeJson(data));
		httpService = httpService.send();

		if (variables.debug) { writeDump(httpService); }

		httpContent = httpService.getPrefix().fileContent;
		responseJson = variables.parseJson(httpContent);

		return responseJson;
	}

	// If JSONUtil is defined, use it to serialize an object to JSON, otherwise fall back to CF's serializer
	private string function serializeJson (
		required data
	) {
		if (structKeyExists(variables, "JSONUtil")) {
			return variables.JSONUtil.serialize(var=arguments.data);
		} else {
			return serializeJson(arguments.data);
		}
	}

	// If JSONUtil is defined, use it to parse JSON string into an object, otherwise fall back to CF's deserializer
	private function parseJson (
		required string json
	) {
		if (structKeyExists(variables, "JSONUtil")) {
			return variables.JSONUtil.deserializeJSON(arguments.json);
		} else {
			return deserializeJson(arguments.json);
		}
	}

	// Converts a struct into a URL query string
	private string function structToQueryString (
		required struct params
	) {
		response = "";

		// Adds default exclude_fields=_links. This drastically reduces the response size from MailChimp
		if (!(structKeyExists(arguments.params, "exclude_fields") || structKeyExists(arguments.params, "fields"))) {
			arguments.params.exclude_fields = "_links";
		}

		for (key in arguments.params) {
			response = listAppend(response, key & "=" & urlEncodedFormat(arguments.params[key]), "&");
		}

		if (len(response) > 0) {
			response = "?" & response;
		}

		return response;
	}

	// In the event of an HTTP error status, parses the detail out of the CF HTTP object
	private string function getErrorFromHttp (
		required struct http
	) {
		return {
			"statusCode" = arguments.http.statusCode,
			"errorDetail" = arguments.http.errorDetail
		};
	}
}
