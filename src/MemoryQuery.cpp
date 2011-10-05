#include <co/Platform.h>

#if defined( CORAL_OS_WIN )
#include <windows.h>
#include <stdio.h>
#include <psapi.h>
#endif

#if defined( CORAL_OS_LINUX )
#include <time.h>
#include <sys/times.h>
#include <sys/resource.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
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
		#if defined( CORAL_OS_WIN )
		DWORD pid = GetCurrentProcessId();
		HANDLE hProcess;
		PROCESS_MEMORY_COUNTERS pmc;

		hProcess = OpenProcess(  PROCESS_QUERY_INFORMATION |
                                    PROCESS_VM_READ,
                                    FALSE, pid );

		GetProcessMemoryInfo( hProcess, &pmc, sizeof(pmc));
		return static_cast<co::int32>( pmc.WorkingSetSize );
		#endif
		#if defined( CORAL_OS_LINUX )
		char buf[30];
		snprintf(buf, 30, "/proc/%u/statm", (unsigned)getpid());
		FILE* pf = fopen(buf, "r");
		if (pf) {
			unsigned size; //       total program size
			unsigned resident;//   resident set size
			fscanf(pf, "%u %u" /* %u %u %u %u"*/, &size, &resident /*, &share, &text, &lib, &data*/);
			fclose(pf);
			return static_cast<co::int32>( size );
		}
		fclose(pf);
		return 0;
		#endif
		return 0;
	}

private:
	// member variables go here
};

CORAL_EXPORT_COMPONENT( MemoryQuery, MemoryQuery );

} // namespace testkit
