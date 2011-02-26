#!/bin/python
####
# Simple Demo Server for dreaMote, powered by twisted web
# Currently supports most e2 functionality also present in dreaMote, and parts
# of the e1 and neutrino functionality are supported.
# Eventually this should properly emulate all used functionality of the
# HTTP based backends.
# Given that VDR does not require extra hardware for testing and is not based
# on HTTP as the other systems, it will not be included here.
####


from twisted.web import server, resource
from twisted.internet import reactor
import time

### DOCUMENTS
GETCURRENT = """<?xml version="1.0" encoding="UTF-8"?>
<e2currentserviceinformation>
	<e2service>
		<e2servicereference>1:0:1:445D:453:1:C00000:0:0:0:</e2servicereference>
		<e2servicename>DemoService</e2servicename>
		<e2providername>DemoProvider</e2providername>
		<e2videowidth>720</e2videowidth>
		<e2videoheight>576</e2videoheight>
		<e2servicevideosize>720x576</e2servicevideosize>
		<e2iswidescreen></e2iswidescreen>
		<e2apid>512</e2apid>
		<e2vpid>511</e2vpid>
		<e2pcrpid>511</e2pcrpid>
		<e2pmtpid>97</e2pmtpid>
		<e2txtpid>33</e2txtpid>
		<e2tsid>1107</e2tsid>
		<e2onid>1</e2onid>
		<e2sid>17501</e2sid>
	</e2service>
	<e2eventlist>
		<e2event>
			<e2eventservicereference>1:0:1:445D:453:1:C00000:0:0:0:</e2eventservicereference>
			<e2eventservicename>DemoService</e2eventservicename>
			<e2eventprovidername>DemoProvider</e2eventprovidername>
			<e2eventid>45183</e2eventid>
			<e2eventname>Demo Eventname</e2eventname>
			<e2eventtitle>Demo Eventname</e2eventtitle>
			<e2eventdescription>Event Short description</e2eventdescription>
			<e2eventstart>%.2f</e2eventstart>
			<e2eventduration>1560</e2eventduration>
			<e2eventremaining>1381</e2eventremaining>
			<e2eventcurrenttime>%.2f</e2eventcurrenttime>
			<e2eventdescriptionextended>Event description</e2eventdescriptionextended>
		</e2event>
		<e2event>
			<e2eventservicereference>1:0:1:445D:453:1:C00000:0:0:0:</e2eventservicereference>
			<e2eventservicename>DemoService</e2eventservicename>
			<e2eventprovidername>DemoProvider</e2eventprovidername>
			<e2eventid>45184</e2eventid>
			<e2eventname>Demo Eventname 2</e2eventname>
			<e2eventtitle>Demo Eventname 2</e2eventtitle>
			<e2eventdescription>Event Short description 2</e2eventdescription>
			<e2eventstart>%.2f</e2eventstart>
			<e2eventduration>1800</e2eventduration>
			<e2eventremaining>1800</e2eventremaining>
			<e2eventcurrenttime>%.2f</e2eventcurrenttime>
			<e2eventdescriptionextended>Event description 2</e2eventdescriptionextended>
		</e2event>
	</e2eventlist>
</e2currentserviceinformation>"""

SIMPLEXMLRESULT = """<?xml version="1.0" encoding="UTF-8"?>
<e2simplexmlresult>
<e2state>%s</e2state>
<e2statetext>%s</e2statetext>
</e2simplexmlresult>"""

ABOUT = """<?xml version="1.0" encoding="UTF-8"?>
<e2abouts>
	<e2about>
		<e2enigmaversion>2011-01-28-experimental</e2enigmaversion>
		<e2imageversion>Experimental 2010-12-17</e2imageversion>
		<e2webifversion>1.6.6</e2webifversion>
		<e2fpversion>None</e2fpversion>
		<e2model>dm800</e2model>
		<e2lanmac>00:09:34:27:9e:9f</e2lanmac>
		<e2landhcp>True</e2landhcp>
		<e2lanip>192.168.45.26</e2lanip>
		<e2lanmask>255.255.255.0</e2lanmask>
		<e2langw>192.168.45.1</e2langw>
		<e2hddinfo>
			<model>ATA(FUJITSU MHZ2320B)</model>
			<capacity>320.072 GB</capacity>
			<free>91.079 GB</free>
		</e2hddinfo>
		<e2tunerinfo>
			<e2nim>
				<name>Tuner A</name>
				<type> Alps BSBE2 (DVB-S2)</type>
			</e2nim>
		</e2tunerinfo>
		<e2servicename>ProSieben</e2servicename>
		<e2servicenamespace></e2servicenamespace>
		<e2serviceaspect></e2serviceaspect>
		<e2serviceprovider>ProSiebenSat.1</e2serviceprovider>
		<e2videowidth>720</e2videowidth>
		<e2videoheight>576</e2videoheight>
		<e2servicevideosize>720x576</e2servicevideosize>
		<e2apid>512</e2apid>
		<e2vpid>511</e2vpid>
		<e2pcrpid>511</e2pcrpid>
		<e2pmtpid>97</e2pmtpid>
		<e2txtpid>33</e2txtpid>
		<e2tsid>1107</e2tsid>
		<e2onid>1</e2onid>
		<e2sid>17501</e2sid>
	</e2about>
</e2abouts>"""

NOSERVICES_E2 = """<?xml version="1.0" encoding="UTF-8"?>
<e2servicelist>
</e2servicelist>"""

SERVICES_E2 = """<?xml version="1.0" encoding="UTF-8"?>
<e2servicelist>
	<e2service>
		<e2servicereference>%s</e2servicereference>
		<e2servicename>%s</e2servicename>
	</e2service>
</e2servicelist>"""

EPGSERVICE = """<?xml version="1.0" encoding="UTF-8"?>
<e2eventlist>
%s
</e2eventlist>"""

EVENTTEMPLATE = """<e2event>
		<e2eventid>45183</e2eventid>
		<e2eventstart>%.2f</e2eventstart>
		<e2eventduration>1560</e2eventduration>
		<e2eventcurrenttime>%.2f</e2eventcurrenttime>
		<e2eventtitle>Demo Event</e2eventtitle>
		<e2eventdescription>Event Short description</e2eventdescription>
		<e2eventdescriptionextended>Event description</e2eventdescriptionextended>
		<e2eventservicereference>%s</e2eventservicereference>
		<e2eventservicename>Demo Service</e2eventservicename>
	</e2event>
"""

TIMERLIST_E2 = """<?xml version="1.0" encoding="UTF-8"?>
<e2timerlist>
%s
</e2timerlist>"""

TIMERTEMPLATE_E2 = """<e2timer>
   <e2servicereference>%s</e2servicereference>
   <e2servicename>Demo Service</e2servicename>
   <e2eit>%d</e2eit>
   <e2name>%s</e2name>
   <e2description>%s</e2description>
   <e2descriptionextended></e2descriptionextended>
   <e2disabled>0</e2disabled>
   <e2timebegin>%d</e2timebegin>
   <e2timeend>%d</e2timeend>
   <e2duration>%d</e2duration>
   <e2startprepare>%d</e2startprepare>
   <e2justplay>%d</e2justplay>
   <e2afterevent>%d</e2afterevent>
   <e2logentries></e2logentries>
   <e2filename></e2filename>
   <e2backoff>0</e2backoff>
   <e2nextactivation></e2nextactivation>
   <e2firsttryprepare>True</e2firsttryprepare>
   <e2state>%d</e2state>
   <e2repeated>%d</e2repeated>
   <e2dontsave>0</e2dontsave>
   <e2cancled>False</e2cancled>
   <e2color>000000</e2color>
   <e2toggledisabled>1</e2toggledisabled>
   <e2toggledisabledimg>off</e2toggledisabledimg>
  </e2timer>"""

MOVIELIST_E2 = """<?xml version="1.0" encoding="UTF-8"?>
<e2movielist>
%s
</e2movielist>"""

MOVIETEMPLATE_E2 = """<e2movie>
		<e2servicereference>1:0:0:0:0:0:0:0:0:0:%s</e2servicereference>
		<e2title>%s</e2title>
		<e2description>%s</e2description>
		<e2descriptionextended>%s</e2descriptionextended>
		<e2servicename>%s</e2servicename>
		<e2time>1298106939</e2time>
		<e2length>0:11</e2length>
		<e2tags></e2tags>
		<e2filename>%s</e2filename>
		<e2filesize>7040976</e2filesize>
	</e2movie>"""

POWERSTATE = """<?xml version="1.0" encoding="UTF-8"?>
<e2powerstate>
	<e2instandby>%s</e2instandby>
</e2powerstate>"""

VOLUME = """<?xml version="1.0" encoding="UTF-8"?>
<e2volume>
	<e2result>True</e2result>
	<e2resulttext>%s</e2resulttext>
	<e2current>40</e2current>
	<e2ismuted>%s</e2ismuted>
</e2volume>"""

SIGNAL_E2 = """<?xml version="1.0" encoding="UTF-8"?>
<e2frontendstatus>
	<e2snrdb>
		12.80 dB
	</e2snrdb>
	<e2snr>
		79 %
	</e2snr>
	<e2ber>
		0
	</e2ber>
	<e2acg>
		76 %
	</e2acg>
</e2frontendstatus>"""

REMOTECONTROL = """<?xml version="1.0" encoding="UTF-8"?>
<e2remotecontrol>
	<e2result>%s</e2result>
	<e2resulttext>%s</e2resulttext>
</e2remotecontrol>"""

LOCATIONLIST = """<?xml version="1.0" encoding="UTF-8"?>
<e2locations>
<e2location>/hdd/movie/</e2location>
</e2locations>"""

FILELIST = """<?xml version="1.0" encoding="UTF-8"?>
<e2filelist>
	%s
</e2filelist>"""

FILE = """<e2file>
 <e2servicereference>%s</e2servicereference>
 <e2isdirectory>%s</e2isdirectory>
 <e2root>%s</e2root>
</e2file>"""

BOXSTATUS = """<?xml version="1.0" encoding="UTF-8"?>
<boxstatus><current_time>1298106939</current_time><standby>0</standby><recording>0</recording><mode>0</mode><ip>127.0.0.1</ip></boxstatus>"""

SERVICES_E1 = """<?xml version="1.0" encoding="UTF-8"?>
 <bouquets>
  <bouquet><reference>4097:7:0:33fc5:0:0:0:0:0:0:/var/tuxbox/config/enigma/userbouquet.33fc5.tv</reference><name>Demo Bouquet</name>
   <service><reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference><name>Demo Service</name><provider>Demo Provider</provider><orbital_position>192</orbital_position></service>
  </bouquet>
</bouquets>"""

EPGSERVICE_E1 = """<?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type="text/xsl" href="/xml/serviceepg.xsl"?>
 <service_epg>
 <service>
 <reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference>
 <name>Demo Service</name>
 </service>
 <event id="0">
 <date>18.09.2008</date>
 <time>16:02</time>
 <duration>3385</duration>
 <description>Demo Event</description>
 <genre>n/a</genre>
 <genrecategory>00</genrecategory>
 <start>1221746555</start>
 <details>Event Details</details>
 </event>
 </service_epg>"""

TIMERLIST_E1 = """<?xml version="1.0" encoding="UTF-8"?>
 <timers>
%s
 </timers>"""

TIMERTEMPLATE_E1 = """<timer>
   <type>%s</type>
   <days>%s</days>
   <action>%s</action>
   <postaction>%s</postaction>
   <status>%s</status>
   <typedata>%d</typedata>
   <service>
    <reference>%s</reference>
    <name>Demo Service</name>
   </service>
   <event>
    <date>%s</date>
    <time>%s</time>
    <start>%d</start>
    <duration>%d</duration>
    <description>%s</description>
   </event>
  </timer>"""

QUERYDELETETIMER_E1 = """<html>
    <head>
        <title>Question</title>
        <link rel="stylesheet" type="text/css" href="webif.css">
        <script>
            function yes()
            {
                document.location = "%s";
            }
            function no()
            {
                document.close();
            }
        </script>
    </head>
    <body>
        <b>ATTENTION</b>: This timer event is currently active.
        <br>
        Do you really want to delete this timer event?
        <br><br>
        <input name="yes" type="button" style="width: 100px; height: 22px; background-color: #1FCB12" value="YES" onClick=javascript:yes()>
        <input name="no" type="button" style="width: 100px; height: 22px; background-color: #CB0303" value="NO" onClick=javascript:no()>
    </body>
</html>"""

DELETETIMERCOMPLETE_E1 = """<html>
    <head>
        <title>Complete</title>
        <link rel="stylesheet" type="text/css" href="webif.css">
        <script>
            function init()
            {
                setTimeout("window.close()", 5000);
            }
        </script>
    </head>
    <body onLoad="init()" onUnload="parent.window.opener.location.reload(true)">
        Timer event deleted successfully.
    </body>
</html>"""

MOVIELIST_E1 = """<?xml version="1.0" encoding="UTF-8"?>
<movies>
   %s
</movies>"""

MOVIETEMPLATE_E1 = """<service><reference>1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:%s</reference><name>%s</name><orbital_position>192</orbital_position></service>"""

SIGNAL_E1 = """<?xml version="1.0" encoding="UTF-8" ?>
 <?xml-stylesheet type="text/xsl" href="/xml/streaminfo.xsl"?>
 <streaminfo>
 <frontend>#FRONTEND#</frontend>
 <service>
 <name>n/a</name>
 <reference></reference>
 </service>
 <provider>n/a</provider>
 <vpid>ffffffffh (-1d)</vpid>
 <apid>ffffffffh (-1d)</apid>

 <pcrpid>ffffffffh (-1d)</pcrpid>
 <tpid>ffffffffh (-1d)</tpid>
 <tsid>0000h</tsid>
 <onid>0000h</onid>
 <sid>0000h</sid>
 <pmt>ffffffffh</pmt>
 <video_format>n/a</video_format>
 <namespace>0000h</namespace>
 <supported_crypt_systems>4a70h Dream Multimedia TV (DreamCrypt)</supported_crypt_systems>

 <used_crypt_systems>None</used_crypt_systems>
 <satellite>n/a</satellite>
 <frequency>n/a</frequency>
 <symbol_rate>n/a</symbol_rate>
 <polarisation>n/a</polarisation>
 <inversion>n/a</inversion>
 <fec>n/a</fec>
 <snr>n/a</snr>
 <agc>n/a</agc>

 <ber>n/a</ber>
 <lock>n/a</lock>
 <sync>n/a</sync>
 <modulation>#MODULATION#</modulation>
 <bandwidth>#BANDWIDTH#</bandwidth>
 <constellation>#CONSTELLATION#</constellation>
 <guardinterval>#GUARDINTERVAL#</guardinterval>
 <transmission>#TRANSMISSION#</transmission>
 <coderatelp>#CODERATELP#</coderatelp>

 <coderatehp>#CODERATEHP#</coderatehp>
 <hierarchyinfo>#HIERARCHYINFO#</hierarchyinfo>
 </streaminfo>"""

SERVICES_NEUTRINO = """<?xml version="1.0" encoding="UTF-8"?>
<zapit>
 <Bouquet type="0" bouquet_id="0000" name="Demo Bouquet" hidden="0" locked="0">
  <channel serviceID="d175" name="Demo Service" tsid="2718" onid="f001"/>
 </Bouquet>
</zapit>"""

EPGSERVICE_NEUTRINO = """<?xml version="1.0" encoding="UTF-8"?>
 <epglist>
 <channel_id>44d00016dca</channel_id>
 <channel_name><![CDATA[Demo Service]]></channel_name>
 <prog>
 <eventid>309903955495411052</eventid>
 <eventid_hex>44d00016dcadd6c</eventid_hex>
 <start_sec>1148314800</start_sec>
 <start_t>18:20</start_t>
 <date>02.10.2006</date>
 <stop_sec>1148316600</stop_sec>
 <stop_t>18:50</stop_t>
 <duration_min>30</duration_min>
 <description><![CDATA[Demo Event]]></description>
 <info1><![CDATA[Event short description]]></info1>
 <info2><![CDATA[Event description.]]></info2>
 </prog>
 </epglist>"""
### /DOCUMENTS

TYPE_E2 = 0
TYPE_E1 = 1
TYPE_NEUTRINO = 2

movies = []
timers = []

class Timer:
	weekdayMon = 1 << 0
	weekdayTue = 1 << 1
	weekdayWed = 1 << 2
	weekdayThu = 1 << 3
	weekdayFri = 1 << 4
	weekdaySat = 1 << 5
	weekdaySun = 1 << 6

	afterEventNothing = 0
	afterEventStandby = 1
	afterEventDeepstandby = 2
	afterEventAuto = 3

	def __init__(self, sRef, begin, end, name, description, eit, disabled, justplay, afterevent, repeated):
		self.sRef = sRef
		self.begin = begin
		self.end = end
		self.name = name
		self.description = description
		self.eit = eit
		self.disabled = disabled
		self.justplay = justplay
		self.afterevent = afterevent
		self.repeated = repeated

	def getType(self):
		PlaylistEntry=1
		SwitchTimerEntry=2
		RecTimerEntry=4
		recDVR=8
		recVCR=16
		recNgrab=131072
		stateWaiting=32
		stateRunning=64
		statePaused=128
		stateFinished=256
		stateError=512
		errorNoSpaceLeft=1024
		errorUserAborted=2048
		errorZapFailed=4096
		errorOutdated=8192
		boundFile=16384
		isSmartTimer=32768
		isRepeating=262144
		doFinishOnly=65536
		doShutdown=67108864
		doGoSleep=134217728
		Su=524288
		Mo=1048576
		Tue=2097152
		Wed=4194304
		Thu=8388608
		Fr=16777216
		Sa=33554432

		now = time.time()
		if self.end < now: typedata = stateFinished
		elif self.begin < now: typedata = stateRunning
		else: typedata = stateWaiting

		if self.afterevent == self.afterEventStandby: typedata |= doGoSleep
		elif self.afterevent == self.afterEventDeepstandby: typedata |= doShutdown
		else:
			pass # TODO: ???

		# TODO: disabled == statePaused ?
		if self.justplay: typedata |= SwitchTimerEntry
		else: typedata |= RecTimerEntry

		typedata |= recDVR # XXX: correctly placed here?

		if self.repeated:
			typedata |= isRepeating
			if self.repeated & self.weekdaySun: typedata |= Su
			if self.repeated & self.weekdayMon: typedata |= Mo
			if self.repeated & self.weekdayTue: typedata |= Tue
			if self.repeated & self.weekdayWed: typedata |= Wed
			if self.repeated & self.weekdayThu: typedata |= Thu
			if self.repeated & self.weekdayFri: typedata |= Fr
			if self.repeated & self.weekdaySat: typedata |= Sa

		return typedata

	type = property(getType)

	def getRepresentation(self, type):
		now = time.time()
		if type == TYPE_E2:
			timerstate = 0
			if self.end < now: timerstate = 3
			elif self.begin < now: timerstate = 2
			return TIMERTEMPLATE_E2 % (self.sRef, 0, self.name, self.description, self.begin, self.end, self.end-self.begin, self.begin-10, self.justplay, self.afterevent, timerstate, self.repeated)
		elif type == TYPE_E1:
			PlaylistEntry=1
			SwitchTimerEntry=2
			RecTimerEntry=4
			recDVR=8
			recVCR=16
			recNgrab=131072
			stateWaiting=32
			stateRunning=64
			statePaused=128
			stateFinished=256
			stateError=512
			errorNoSpaceLeft=1024
			errorUserAborted=2048
			errorZapFailed=4096
			errorOutdated=8192
			boundFile=16384
			isSmartTimer=32768
			isRepeating=262144
			doFinishOnly=65536
			doShutdown=67108864
			doGoSleep=134217728
			Su=524288
			Mo=1048576
			Tue=2097152
			Wed=4194304
			Thu=8388608
			Fr=16777216
			Sa=33554432

			if self.end < now:
				typedata = stateFinished
				status = "FINISHED"
			elif self.begin < now:
				typedata = stateRunning
				status = "ACTIVE"
			else:
				typedata = stateWaiting
				status = "ACTIVE" # ???

			if self.afterevent == self.afterEventStandby:
				typedata |= doGoSleep
				postaction = "Standby"
			elif self.afterevent == self.afterEventDeepstandby:
				typedata |= doShutdown
				postaction = "Shutdown"
			else:
				# TODO: all ???
				postaction = "None"

			# TODO: disabled == statePaused ?
			if self.justplay:
				typedata |= SwitchTimerEntry
				action = "ZAP"
			else:
				typedata |= RecTimerEntry
				action = "DVR"

			typedata |= recDVR # XXX: correctly placed here?

			if self.repeated:
				typeString = "REPEATING"
				day = ""
				typedata |= isRepeating
				if self.repeated & self.weekdaySun:
					typedata |= Su
					days += "Su "
				if self.repeated & self.weekdayMon:
					typedata |= Mo
					days += " Mo"
				if self.repeated & self.weekdayTue:
					typedata |= Tue
					days += "Tue "
				if self.repeated & self.weekdayWed:
					typedata |= Wed
					days += "Wed "
				if self.repeated & self.weekdayThu:
					typedata |= Thu
					days += "Thu "
				if self.repeated & self.weekdayFri:
					typedata |= Fr
					days += "Fr "
				if self.repeated & self.weekdaySat:
					typedata |= Sa
					days += "Sa "
			else:
				typeString = "SINGLE"
				days = ""

			dateString = time.strftime('%d.%m.%Y', time.localtime(self.begin))
			timeString = time.strftime('%H:%M', time.localtime(self.begin))
			return TIMERTEMPLATE_E1 % (typeString, days, action, postaction, status, typedata, self.sRef, dateString, timeString, self.begin, self.end-self.begin, self.description)

class State:
	def __init__(self):
		self.movies = []
		self.timers = []
		self.is_muted = False
		self.reset()

	def reset(self):
		self.setupMovies()
		self.setupTimers()

	def setupMovies(self):
		del self.movies[:]
		self.movies.append(('/hdd/movie/Demofilename.ts', 'Recording title', 'Recording short description', 'Recording description', 'Demo Service'))

	def getMovies(self, type):
		moviestrings = ''
		for movie in self.movies:
			fname, title, desc, edesc, sname = movie
			if type == TYPE_E2:
				moviestrings += MOVIETEMPLATE_E2 % (fname, title, desc, edesc, sname, fname)
			elif type == TYPE_E1:
				moviestrings += MOVIETEMPLATE_E1 % (fname, title)
		return moviestrings

	def deleteMovie(self, sRef, type):
		if type == TYPE_E2:
			if sRef == '1:0:0:0:0:0:0:0:0:0:/hdd/movie/Demofilename.ts' and len(self.movies):
				movies.pop()
				return True
		elif type == TYPE_E1:
			if sRef == '1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:/hdd/movie/Demofilename.ts' and len(self.movies):
				movies.pop()
				return True
		return False

	def addTimer(self, sRef, begin, end, name, description, eit, disabled, justplay, afterevent, repeated):
		timer = Timer(sRef, begin, end, name, description, eit, disabled, justplay, afterevent, repeated)
		self.timers.append(timer)
		return timer

	def getTimers(self, type):
		timerstrings = ''
		for timer in self.timers:
			timerstrings += timer.getRepresentation(type)
		return timerstrings

	def deleteTimer(self, sRef, begin, end):
		idx = 0
		for timer in self.timers:
			if timer.sRef == sRef and timer.begin == begin and timer.end == end:
				del self.timers[idx]
				return True
			idx += 1
		return False

	def findTimer(self, findSref, findBegin):
		for timer in self.timers:
			if timer.sRef == findSref and timer.begin == findBegin: return timer
		return None

	def setupTimers(self):
		del self.timers[:]
		self.addTimer('1:0:1:445D:453:1:C00000:0:0:0:', 1205093400, 1205097600, "Demo Timer", "Timer description", 0, 0, 0, 0, 0)

	def toggleMuted(self):
		self.is_muted = not self.is_muted

	def setMuted(self, mute):
		self.is_muted = mute

	def isMuted(self):
		return self.is_muted

state = State()

# returns sample documents, stupid demo contents :-)
class Simple(resource.Resource):
	isLeaf = True
	def render_GET(self, req):
		def get(name, default=None):
			ret = req.args.get(name)
			return ret[0] if ret else default
		lastComp = req.postpath[-1]
# ENIGMA2
		if lastComp == "getcurrent":
			now = time.time()
			returndoc = GETCURRENT % (now-179, now, now+1381, now)
		elif lastComp == "recordnow":
			returndoc = SIMPLEXMLRESULT % ('True', 'instant record started')
		elif lastComp == "about":
			returndoc = ABOUT
		elif lastComp == "zap":
			sRef = req.args.get('sRef')
			sRef = sRef and sRef[0]
			returndoc = SIMPLEXMLRESULT % ('True', 'Active service switched to '+sRef)
		elif lastComp == "getservices":
			sRef = req.args.get('sRef')
			sRef = sRef and sRef[0]
			RADIO = '1:7:2:0:0:0:0:0:0:0:(type == 2)FROM BOUQUET "bouquets.radio" ORDER BY bouquet'
			FAVOURITES = '1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.favourites.tv" ORDER BY bouquet'
			FAVOURITES_RADIO = '1:7:2:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.favourites.radio" ORDER BY bouquet'
			if sRef == FAVOURITES:
				returndoc = SERVICES_E2 % ('1:0:1:445D:453:1:C00000:0:0:0:', 'Demo Service')
			elif sRef == FAVOURITES_RADIO:
				returndoc = SERVICES_E2 % (':::::::::::DUNNO:::::::::::', 'Demo Radio Service')
			elif sRef == RADIO:
				returndoc = SERVICES_E2 % (FAVOURITES_RADIO, 'Demo Radio Bouquet')
			elif not sRef: # XXX: what is real tv bouquets sref?
				returndoc = SERVICES_E2 % (FAVOURITES, 'Demo Bouquet')
			else:
				returndoc = NOSERVICES_E2
		elif lastComp == "epgnow" or lastComp == "epgnext":
			sRef = req.args.get('bRef')
			sRef = sRef and sRef[0]
			FAVOURITES = '1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.favourites.tv" ORDER BY bouquet'
			FAVOURITES_RADIO = '1:7:2:0:0:0:0:0:0:0:FROM BOUQUET "userbouquet.favourites.radio" ORDER BY bouquet'
			if sRef and sRef in (FAVOURITES, FAVOURITES_RADIO):
				now = time.time()
				if lastComp == "epgnext": now += 1560
				event = EVENTTEMPLATE % (now, now, sRef)
				returndoc = EPGSERVICE % (event,)
			else:
				returndoc = "UNHANDLED REQUEST"
		elif lastComp == "epgservice":
			sRef = req.args.get('sRef')
			sRef = sRef and sRef[0]
			if sRef:
				now = time.time()
				event = EVENTTEMPLATE % (now, now, sRef)
				returndoc = EPGSERVICE % (event,)
			else:
				returndoc = EPGSERVICE % ('',)
		elif lastComp == "powerstate":
			returndoc = POWERSTATE % ('false',)
		elif lastComp == "vol":
			set = req.args.get('set')
			set = set and set[0]
			if set:
				if len(set) > 3 and set[:3] == 'set':
					vol = int(set[3:])
					message = "Volume set to %d" % (vol,)
				elif set == 'mute':
					state.toggleMuted()
					message = "Mute toggled"
				else:
					message = "OMFG SOMETHING WENT WRONG"
			else:
				message = "State"
			returndoc = VOLUME % (message, 'True' if state.isMuted() else 'False')
		elif lastComp == "signal":
			returndoc = SIGNAL_E2 # TODO: add jitter?
		elif lastComp == "remotecontrol":
			command = int(req.args.get('command')[0])
			if command > 0:
				returndoc = REMOTECONTROL % ('True', "RC command '"+str(command)+"' has been issued")
			else:
				returndoc = REMOTECONTROL % ('False', 'the command was not &gt; 0')
		elif req.path == "/web/message":
			text = req.args.get('text')
			ttype = req.args.get('type')
			if not text or not text[0]:
				returndoc = SIMPLEXMLRESULT % ('False', 'No Messagetext given')
			else:
				try: ttype = int(ttype[0])
				except: returndoc = SIMPLEXMLRESULT % ('False', 'Type %s is not a number' % (ttype[0],))
				else: returndoc = SIMPLEXMLRESULT % ('True', 'Message sent successfully!')
		elif lastComp == "grab":
			returndoc = "Grab is not installed at /usr/bin/grab. Please install package aio-grab." # TODO: add sample pictures?
		elif lastComp == "epgsearch":
			search = req.args.get('search')
			event = ''
			if search and search[0] in "Demo Event":
				now = time.time()
				event = EVENTTEMPLATE % (now, now, '1:0:1:445D:453:1:C00000:0:0:0:')
			returndoc = EPGSERVICE % (event,)
		elif lastComp == "epgsimilar":
			# e2 webif i used for testing crashes on not given / wrong eit, copy this behavior :-D
			eit = int(req.args.get('eventid')[0])

			returndoc = EPGSERVICE % ('',)
### TIMERS
		elif lastComp == "timerlist":
			timerstrings = state.getTimers(TYPE_E2)
			returndoc = TIMERLIST_E2 % (timerstrings,)
		elif lastComp == "timeradd" or lastComp == "timerchange":
			if lastComp == "timerchange":
				delete = int(req.args.get('deleteOldOnSave', 0)[0])
				sRef = req.args.get('channelOld')[0]
				begin = int(req.args.get('beginOld')[0])
				end = int(req.args.get('endOld')[0])
				if delete: state.deleteTimer(channelOld, beginOld, endOld)
			sRef = req.args.get('sRef')[0]
			begin = int(req.args.get('begin')[0])
			end = int(req.args.get('end')[0])
			name = req.args.get('name')[0]
			desc = req.args.get('description')[0]
			eit = int(req.args.get('eit')[0])
			disabled = int(req.args.get('disabled')[0])
			justplay = int(req.args.get('justplay')[0])
			afterevent = int(req.args.get('afterevent')[0])
			repeated = int(req.args.get('repeated')[0])
			state.addTimer(sRef, begin, end, name, desc, eit, disabled, justplay, afterevent, repeated)
			if lastComp == "timerchange":
				returndoc = SIMPLEXMLRESULT % ('True', 'Timer changed successfully')
			else:
				returndoc = SIMPLEXMLRESULT % ('True', 'Timer added successfully')
		elif lastComp == "timerdelete":
			sRef = req.args.get('sRef')[0]
			begin = int(req.args.get('begin')[0])
			end = int(req.args.get('end')[0])
			if state.deleteTimer(sRef, begin, end): returndoc = SIMPLEXMLRESULT % ('True', 'SOME TEXT')
			else: returndoc = SIMPLEXMLRESULT % ('False', 'No matching Timer found')
### /TIMERS
### MOVIES
		elif lastComp == "getlocations":
			returndoc = LOCATIONLIST
		elif lastComp == "movielist":
			returndoc = MOVIELIST_E2 % (state.getMovies(TYPE_E2),)
		elif lastComp == "moviedelete":
			sRef = req.args.get('sRef')
			sRef = sRef and sRef[0]
			if state.deleteMovie(sRef, TYPE_E2):
				returndoc = SIMPLEXMLRESULT % ('True', "SOME TEXT'")
			else:
				returndoc = SIMPLEXMLRESULT % ('False', "Could not delete Movie 'this recording'")
### /MOVIES
### MEDIAPLAYER
		elif lastComp == "mediaplayerlist":
			path = req.args.get('path')
			path = path and path[0]
			if path == "playlist":
				files = FILE % ("empty", "True", "playlist")
			else:
				files = ''
			returndoc = FILELIST % (files,)
### /MEDIAPLAYER
# ENIGMA
		elif lastComp == "boxstatus":
			returndoc = BOXSTATUS
		elif lastComp == "zapTo":
			returndoc = "IMO RETURN OF E1 SUCKS"
		elif lastComp == "services":
			mode = req.args.get('mode')
			submode = req.args.get('submode')
			mode = mode and int(mode[0])
			submode = submode and int(submode[0])
			if mode == 3 and submode == 4:
				returndoc = MOVIELIST_E1 % (state.getMovies(TYPE_E1),)
			else:
				returndoc = SERVICES_E1
		elif lastComp == "serviceepg":
			sRef = req.args.get('ref')
			sRef = sRef and sRef[0]
			return EPGSERVICE_E1
### TIMERS
		elif lastComp == "timers":
			timerstrings = state.getTimers(TYPE_E1)
			returndoc = TIMERLIST_E1 % (timerstrings,)
		elif lastComp == "addTimerEvent":
			sRef = get('ref')
			# TODO: support string time, not just unix timestamps
			start = int(get('start', -1))
			duration = int(get('duration', 0))
			descr = get('descr', '')
			after_event = int(get('after_event', 0))
			action = get('action')
			repeating = True if get('type', '') == "repeating" else False
			mo = get('mo', '') == 'on'
			tu = get('tu', '') == 'on'
			we = get('we', '') == 'on'
			th = get('th', '') == 'on'
			fr = get('fr', '') == 'on'
			sa = get('so', '') == 'on'
			su = get('su', '') == 'on'
			# TODO: are there additional parameters I left out b/c dreamote does not use them?
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "deleteTimerEvent":
			sRef = get('ref')
			start = int(get('start', -1))
			type = int(get('type', -1))
			force = True if get('force', 'no') == "yes" else False
			timer = state.findTimer(sRef, start)
			now = time.time()
			if timer and timer.type == type and timer.begin < now and not timer.end < now and not force:
				newUri = req.uri.replace('force=no', 'force=yes')
				if not 'force=yes' in newUri and '?' in newUri:
					newUri += '&force=yes'
				returndoc = QUERYDELETETIMER_E1 % (newUri,)
			else:
				returndoc = DELETETIMERCOMPLETE_E1
### /TIMERS
		elif lastComp == "deleteMovie":
			sRef = req.args.get('ref')
			sRef = sRef and sRef[0]
			state.deleteMovie(sRef, TYPE_E1)
			returndoc = "IMO RETURN OF E1 SUCKS"
		elif lastComp == "videocontrol":
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "currentservicedata":
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "admin":
			command = req.args.get('command')
			command = command and command[0]
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "audio":
			toggleMute = 'mute' in req.args
			if toggleMute:
				state.toggleMuted()
				returndoc = """mute set
volume: 0
mute: %d""" % (1 if state.isMuted() else 0,)
			else:
				returndoc = """Volume set.
volume: 0
mute: %d""" % (1 if state.isMuted() else 0,)
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "rc":
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "streaminfo":
			returndoc = SIGNAL_E1 # TODO: add jitter?
		elif lastComp == "xmessage":
			body = req.args.get('body')
			caption = req.args.get('caption')
			timeout = req.args.get('timeout')
			icon = req.args.get('icon')
			body = body and body[0]
			caption = caption and caption[0]
			timeout = timeout and int(timeout[0])
			icon = icon and int(icon[0])
			returndoc = "UNHANDLED METHOD"
# NEUTRINO
		elif lastComp == "info":
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "zapto":
			# action depends on arg, there are fixed value but if you give a service name or id it will zap to that channel
			returndoc = "UNHANDLED METHOD"
		elif lastComp == "getbouquetsxml":
			returndoc = SERVICES_NEUTRINO
		elif lastComp == "epg":
			isXml = req.args.get('xml')
			isXml = True if isXml and isXml[0] == 'true' else False
			sRef = req.args.get('channelId') or req.args.get('channelid') # XXX: api suggest channelid is correct though channelId seems to be ok too
			sRef = sRef and sRef[0]
			sname = req.args.get('channel_name')
			sname = sname and sname[0]
			details = req.args.get('details')
			details = True if details and details[0] == 'true' else False
			max = req.args.get('max')
			max = int(max[0]) if max and max[0] else -1
			if not isXml or not details or max == -1:
				returndoc = "UNHANDLED METHOD"
			else:
				if sRef and sRef in ("d175", "2718f001d175") or sname and sname == "Demo Service":
					return EPGSERVICE_NEUTRINO
				else:
					returndoc = "UNHANDLED METHOD"
		elif lastComp == "timer":
			action = req.args.get('action')
			action = action and action[0]
			if not action:
				useId = req.args.get('format')
				useId = True if useId and useId[0] == 'id' else False
				data = "2718f001d175" if useId else "Demo Service"
				# XXX: static response based on sample in nhttpd documentation which seemed to be buggy though
				returndoc = "1 5 0 0 1034309516 1034284376 1034309576 "+data
			elif action == "new" or action == "modify":
				returndoc = "UNHANDLED METHOD"
			elif action == "remove":
				# XXX: list currently has static response
				id = req.args.get('id')
				id = int(id) if id and id[0] else 0
				if id == 0 or id > len(state.timers):
					pass
				else:
					del state.timers[id]
				returndoc = "IMO RETURN OF NEUTRINO SUCKS"
			else:
				returndoc = "UNHANDLED METHOD"
		elif lastComp == "shutdown" or lastComp == "reboot":
			returndoc = "ok"
		elif lastComp == "standby":
			if 'on' in req.args:
				returndoc = "ok"
			elif 'off' in req.args:
				returndoc = "ok"
			else:
				returndoc = "off" # or on :P
		elif lastComp == "volume":
			if 'status' in req.args:
				returndoc = '1' if state.isMuted() else '0'
			elif 'mute' in req.args:
				state.setMuted(True)
				returndoc = 'mute'
			elif 'unmute' in req.args:
				state.setMuted(False)
				returndoc = 'unmute'
			else:
				# gui does not really care about return and i don't feel like implementing this
				returndoc = "whatever dude"
		elif lastComp == "setmode":
			returndoc = "ok"
		elif lastComp == "rcem":
			returndoc = "ok"
		elif req.path == "/control/message":
			if 'nmsg' in req.args:
				returndoc = ''
			elif 'popup' in req.args:
				returndoc = ''
			else:
				returndoc = "UNHANDLED METHOD"
# CUSTOM
		elif lastComp == "RESET":
			state.reset()
			returndoc = "reset of demo server triggered"
		elif lastComp == '':
			# XXX: this actually indicates a trailing slash, but we use this to detect requests for /
			returndoc = """<html><head><title>dreaMote Demo Server</title></head><body>
<pre>Welcome to the dreaMote Demo Server.
This is a really dumb piece of software that emulates the HTTP-APIs to Enigma2, Enigma and Neutrino.

It does in no way claim to be complete or correct, but it can be used to test the functionality of dreaMote.
You may use this to test other software, but keep in mind that this may yield false positive errors in the software.
I welcome you though to tell me about these bugs so they can be fixed in future versions.

Since parts of the functionality removes information from the database (e.g. deleting movies) that normally could not be reversed this software has a reset functionality.</pre>
<a href="/RESET">Just click here!</a><br />
<pre>So have fun testing your software...

Oh, I almost forgot: to change the listening port, just add the one you want to the command line (e.g. python bin/dreamote_demo_server.py 31337)</pre>
</body></html>"""
		else:
			returndoc = "UNHANDLED DOCUMENT"

		print req.uri, returndoc
		return returndoc

def main(port):
	site = server.Site(Simple())
	print "Listening on port", port
	reactor.listenTCP(port, site)
	reactor.run()

if __name__ == '__main__':
	from sys import argv
	port = 8080 if len(argv) != 2 else int(argv[1])
	main(port)
