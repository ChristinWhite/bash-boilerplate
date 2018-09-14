#!/usr/bin/env bash

# # Temporary Testing
temp_test() {

	# TODO: Switch to proper tests.

	test_print_logs() {
		notice "BEGIN: test_print_logs"

		# Should pass
		debug "Sample debug"
		info "Sample info"
		notice "Sample notice"
		warning "Sample warning"
		error "Sample error"
		critical "Sample critical"
		alert "Sample alert"
		# __log "invalid" "This is an invalid log_level, defaults to error formatting."

		# Should fail
		# debug
		# info
		# notice
		# warning
		# error
		# critical
		# alert
		# __log "invalid"

		# Should fail with exit in subshell
		( emergency "Sample emergency (without exit)" ) || true

		notice "COMPLETED: test_print_logs // exit: ${?}"
	}

	test_prompt() {
		notice "BEGIN: test_prompt"

		# Should pass
		__prompt "Sample prompt text"

		# Should fail
		__prompt

		notice "COMPLETED: test_prompt // exit: ${?}"
	}

	test_print_header() {
		notice "BEGIN: test_print_header"

		# Should pass
		__print_header "${__header:-}" || true

		# Should fail
		local __header=""
		__print_header || true

		notice "COMPLETED: test_print_header // exit: ${?}"
	}

	test_validate_commands() {
		notice "BEGIN: test_validate_commands"

		# Should pass
		notice "Passing Tests"
		__validate_commands "cd"
		__validate_commands "ls" "echo"
		__validate_commands --pass "info" "cd"
		if __validate_commands -s "cd"; then debug "Validated silently"; fi
		if __validate_commands --silent "ls" "echo"; then debug "Validated silently"; fi

		# Should fail
		notice "Failing Tests:"
		__validate_commands "failure"
		__validate_commands "this" "will" "not" "pass"
		__validate_commands -f "warning" "failure"
		__validate_commands --fail "critical" "this" "will" "not" "pass"

		# Should fail with exit in subshell
		notice "Failing with (exit) Tests:"
		( __validate_commands -r "failure" )
		( __validate_commands --required "this" "will" "not" "pass" )
		( __validate_commands -f "emergency" "failure" )
		if ! ( __validate_commands -s -r "failure" ); then warning "Failed sillently"; fi
		if ! (__validate_commands --silent -r "this" "will" "not" "pass" ); then warning "Failed sillently"; fi

		notice "COMPLETED: test_validate_commands // exit: ${?}"
	}

	test_validate_resources() {
		local test_directory="/Users/cwhite/Source/open-source/bash-boilerplate/test"
		local is_missing="${test_directory}/resources/is_missing"
		local is_existing="${test_directory}/resources/is_existing"
		local is_readable="${test_directory}/resources/is_readable"
		local is_writable="${test_directory}/resources/is_writable"
		local is_executable="${test_directory}/resources/is_executable"
		local is_folder="${test_directory}/resources/is_folder/"

		notice "BEGIN: test_validate_commands"

		## Should pass
		notice "Passing Tests:"
		__validate_resources "${is_existing}" "${is_folder}"
		__validate_resources -R "${is_readable}"
		__validate_resources --readable "${is_readable}"
		__validate_resources -w "${is_writable}"
		__validate_resources --writable "${is_writable}"
		__validate_resources -x "${is_executable}"
		__validate_resources --executable "${is_executable}"
		__validate_resources -p "info" "${is_existing}"
		__validate_resources --pass "info" "${is_existing}"
		__validate_resources --readable --writable --executable "${is_executable}"
		if __validate_resources -s "${is_existing}"; then debug "Validated silently"; fi
		if __validate_resources --silent "${is_folder}"; then debug "Validated silently"; fi
		__validate_resources -r "${is_existing}"
		__validate_resources --required "${is_folder}"

		## Should fail
		notice "Failing Tests:"
		__validate_resources "${is_missing}"
		__validate_resources "${is_existing}" "${is_missing}" "${is_folder}"
		__validate_resources -R "${is_existing}"
		__validate_resources --readable "${is_existing}"
		__validate_resources -w "${is_readable}"
		__validate_resources --writable "${is_readable}"
		__validate_resources -x "${is_writable}"
		__validate_resources --executable "${is_writable}"
		__validate_resources -f "critical" "${is_missing}"
		__validate_resources --fail "critical" "${is_missing}"
		__validate_resources --readable --writable --executable "${is_missing}" "${is_existing}" "${is_readable}" "${is_writable}" "${is_executable}"
		if ! __validate_resources -s "${is_missing}"; then warning "Failed silently"; fi
		if ! __validate_resources --silent "${is_missing}"; then warning "Failed silently"; fi

		## Should fail with exit in subshell
		notice "Failing with (exit) Tests:"
		( __validate_resources -r "${is_missing}" )
		( __validate_resources --required "${is_missing}" )
		( __validate_resources -r --readable --writable --executable "${is_missing}" "${is_existing}" "${is_readable}" "${is_writable}" "${is_executable}" )
		( __validate_resources -f "emergency" "${is_missing}" )
		if ! ( __validate_resources -s -r "${is_missing}" ); then warning "Failed sillently"; fi
		if ! (__validate_resources --silent -r "${is_missing}" ); then warning "Failed sillently"; fi

		notice "COMPLETED: test_validate_commands // exit: ${?}"
	}

	test_validate_repositories() {
		local https="https://github.com/christopherdwhite/bash-boilerplate.git"
		local ssh="git@github.com:christopherdwhite/bash-boilerplate.git"

		notice "BEGIN: test_validate_repositories"

		# Should pass
		notice "Passing Tests:"
		__validate_repositories "${https}"
		__validate_repositories "${https}" "${ssh}"
		__validate_repositories --pass "info" "${https}"
		if __validate_commands -s "${https}"; then debug "Validated silently"; fi
		if __validate_commands --silent "${https}" "${ssh}"; then debug "Validated silently"; fi

		# Should fail
		notice "Failing Tests:"
		__validate_repositories "http://not-a-repo.com"
		__validate_repositories "http://not-a-repo.com" "Also not a repo"
		__validate_commands -f "warning" "http://not-a-repo.com"
		__validate_commands --fail "critical" "http://not-a-repo.com"


		# Should fail with exit in subshell
		notice "Failing with (exit) Tests:"
		( __validate_repositories -r "http://not-a-repo.com" )
		( __validate_repositories --required "http://not-a-repo.com" "Also not a repo" )
		( __validate_repositories -f "emergency" "http://not-a-repo.com" )
		if ! ( __validate_repositories -s -r "http://not-a-repo.com" ); then warning "Failed sillently"; fi
		if ! (__validate_repositories --silent -r "http://not-a-repo.com" ); then warning "Failed sillently"; fi

		notice "COMPLETED: test_validate_repositories // exit: ${?}"
	}

	# ## Call Tests
	# test_print_logs
	# test_print_header
	# test_prompt
	# test_validate_commands
	# test_validate_resources
	# test_validate_repositories

	NotACommand
	NotACommandWithParamaters these are parameters
	(NotASubShellCommand)
	( (( 1 + 5 == 12 )) )

}
