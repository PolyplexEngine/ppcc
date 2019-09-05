/**
    This file contains various global state
*/
module state;

// Everything is marked gshared in case multi-thread project building gets added in the future
__gshared:

/// Wether the application is in verbose mode (-v flag)
bool VERBOSE_MODE;
