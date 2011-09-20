#include <co/Platform.h>

#if defined( CORAL_OS_WIN )
#include <windows.h>
#include <stdio.h>
#include <psapi.h>
#endif

#include "MemoryQuery_Base.h"

namespace testkit {

class MemoryQuery : public MemoryQuery_Base
{
public:
	MemoryQuery()
	{
		// empty constructor
	}

	virtual ~MemoryQuery()
	{
		// empty destructor
	}

	// ------ testkit.IMemoryQuery Methods ------ //

	co::int32 getUsedMemory()
	{
		DWORD pid = GetCurrentProcessId();
		HANDLE hProcess;
		PROCESS_MEMORY_COUNTERS pmc;

		hProcess = OpenProcess(  PROCESS_QUERY_INFORMATION |
                                    PROCESS_VM_READ,
                                    FALSE, pid );

		GetProcessMemoryInfo( hProcess, &pmc, sizeof(pmc));
		return static_cast<co::int32>( pmc.WorkingSetSize );
	}

private:
	// member variables go here
};

CORAL_EXPORT_COMPONENT( MemoryQuery, MemoryQuery );

} // namespace testkit
