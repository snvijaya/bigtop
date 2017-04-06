/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * <p/>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p/>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.bigtop.itest.hivesmoke

import org.apache.bigtop.itest.JarContent
import org.apache.bigtop.itest.shell.Shell
import static junit.framework.Assert.assertEquals

public class HiveBulkScriptExecutor {
  static Shell sh = new Shell("/bin/bash -s");

  private File scripts;
  private String location;
  private String nativeHiveOutputPath;

  public HiveBulkScriptExecutor(String l, String n) {
    location = HiveBulkScriptExecutor.class.getResource(l).getPath();
    scripts = new File(location);
    //nativeHiveOutputPath = HiveBulkScriptExecutor.class.getResource('seed.hql').getPath();
    nativeHiveOutputPath = HiveBulkScriptExecutor.class.getResource(n).getPath(); 
    println "SN: location =" + location
    println "SN: scripts =" + scripts
    println "SN: nativeHiveOutputPath =" + nativeHiveOutputPath

/*    if (!scripts.exists()) {
      JarContent.unpackJarContainer(HiveBulkScriptExecutor.class, '.' , null);
    }
*/
  }

  public List<String> getScripts() {
    List<String> res = [];

    try {
      scripts.eachDir { res.add(it.name); }
    } catch (Throwable ex) {}
    return res;
  }


  public void runScript(String test, String extraArgs) {
    String l = "${location}/${test}";
    String n = "${nativeHiveOutputPath}/${test}";
    println "runScript 2 args for " + l + " compare with " + n
    def scriptDir = getClass().protectionDomain.codeSource.location.path
    def runDir = System.getProperty("user.dir");
    
    sh.exec("""
    set -x
    pwd
    cd ${l}
    cd ../../../
    pwd
    hive ${extraArgs} -f ${l}/in > ${l}/actual  
    cat ${l}/actual
    cat ${n}/actual 
    sudo diff ${l}/actual ${n}/actual
    """);
    println "***SN: hive script run complete"
    println sh.out
    println "***SN: hive err any ? "
    println sh.err
    println "***SN: ret code" + sh.ret
    assertEquals("Got unexpected output from test script ${test}",
                  0, sh.ret);
  }

  public void runScript(String test) {
    println "runScript " + test
    runScript(test, "");
  }
}
