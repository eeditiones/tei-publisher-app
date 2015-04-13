An implementation of the TEI Simple ODD extensions for processing models in XQuery.

# Building

Due to a bug in the 2.2 release, the tei-simple module needs the current development version of eXist. Get it from
https://github.com/eXist-db/exist

For PDF output, you need to enable the Apache FOP extension as follows:

* in extensions/build.properties, set "include.module.xslfo = true"
* rebuild eXist to install the Apache FOP libraries
* edit conf.xml and uncomment the fo module:

```xml
<module uri="http://exist-db.org/xquery/xslfo" class="org.exist.xquery.modules.xslfo.XSLFOModule">
    <parameter name="processorAdapter" value="org.exist.xquery.modules.xslfo.ApacheFopProcessorAdapter"/>
</module>
```

tei-simple-pm ships as a .xar package which can be installed into any eXist instance using the dashboard. You may get the
latest .xar here:

https://github.com/wolfgangmm/tei-simple-pm/releases/tag/0.2

To build tei-simple-pm, clone the repository and call "ant" in the root directory. This will create a .xar inside the build directory.

# License

This software is dual-licensed: 

1. Distributed under a Creative Commons Attribution-ShareAlike 3.0 Unported License
http://creativecommons.org/licenses/by-sa/3.0/ 

2. http://www.opensource.org/licenses/BSD-2-Clause 

All rights reserved. Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met: 

* Redistributions of source code must retain the above copyright notice, this list of 
conditions and the following disclaimer. 
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution. 

This software is provided by the copyright holders and contributors "as is" and any 
express or implied warranties, including, but not limited to, the implied warranties 
of merchantability and fitness for a particular purpose are disclaimed. In no event 
shall the copyright holder or contributors be liable for any direct, indirect, 
incidental, special, exemplary, or consequential damages (including, but not limited to, 
procurement of substitute goods or services; loss of use, data, or profits; or business
interruption) however caused and on any theory of liability, whether in contract,
strict liability, or tort (including negligence or otherwise) arising in any way out
of the use of this software, even if advised of the possibility of such damage.