#ifndef ERROR_HEADER_H
#define ERROR_HEADER_H

#include <string>

/**
 * Module: error
 * This module is used to generate the strings 
 * for you to have consistent error messages.
 */

namespace error
{
	// Two nodes have the same uid that is supposed to be unique.
	std::string identical_uid(unsigned int uid);
	
	// One of the nodes indicated for a link does not exist.
	std::string link_vacuum(unsigned int uid);
	
	// A housing node number of links exceeds the allowed maximum number 
	std::string max_link(unsigned int uid);
	
	// The same link is defined several times
	std::string multiple_same_link(unsigned int uid1, unsigned int uid2);
	
	// A node overlap a link 
	std::string node_link_superposition(unsigned int uid);
	
	// Two nodes overlap 
	std::string node_node_superposition(unsigned int uid1, unsigned int uid2);
	
	// A node is using the reserved uid
	std::string reserved_uid();
	
	// Everything went well => file reading and all validation checks
	std::string success();
	
	// A link refers twice to the same node
	std::string self_link_node(unsigned int uid);
	
	// A node that has too little capacity
	std::string too_little_capacity(unsigned int capacity);
	
	// A node that has too much capacity
	std::string too_much_capacity(unsigned int capacity);
}

#endif // ERROR_HEADER_H
