<master>
  <property name="title">@package_instance_name@</property>
 <p>
  General Ledger provides services to other packages and provides a basic UI for directly managing a ledger and accounts.
 </p>
<h3>
 Features
</h3>
<h4>Converted:</h4>
<ul><li>
Data model for Postgresql including preloading chart templates and language translations when installing.
</li><li>
Num2text in SL, lc_number_to_text in accounts-payables package
</li></ul>
<h4>Planned:</h4>
 <p>
Basic general ledger posting via web and service (and/or callback?), and editing chart templates.  One ledger per package instance.  See sql-ledger's <a href="http://sql-ledger.org/cgi-bin/nav.pl?page=features.html&title=Features" target="_blank">features</a> and <a href="http://sql-ledger.org/cgi-bin/nav.pl?page=news.html&title=What's%20New" target="_blank">What's new</a> pages.
 </p>
<h3>
notes</h3>
<pre>
sql-ledger        package-key  table name

&lt;table_name&gt;        qal_&lt;table_name&gt;


</pre><p>
Need to add package_key to data model.
</p><h3>
porting notes and guidelines
</h3><p>
The locale data has been extracted using a custom program located in the accounts-ledger/info directory of this package. Configuration data is set in convert.tcl. Be sure to remove xml language files in accounts-ledger/catalog/ before running the program.  An error while running convert-SL-charts.tcl may be caused by multiple line queries in the chart files. The program should handle it now, but it has not been tested.
</p><p>
Any functions dependent on either AP or AR data are moved to those packages. When something is dependent on two or more accounting packages, it is moved into the "full accounting features" accounts-desk package.
</p>
<p>
Each package has a set of Model-View-Control features and services.  Most any of these packages should provide a basic level of features without requiring other packages. Optional (integrated) features are built into the packages where appropriate.
</p><h3>
Table of package dependencies
</h3><table border="1" cellspacing="0" cellpadding="3">
<tr>
<th>package-key</th><th>depends on</th>
</tr><tr>
<td>accounts-ledger </td><td>online-catalog (and maybe inventory-control) for parts sales management), contacts?</td>
</tr><tr>
<td>accounts-payable      </td><td>accounts-ledger, contacts</td>
</tr><tr>
<td>accounts-receivables  </td><td>accounts-ledger, contacts</td>
</tr><tr>
<td>accounts-desk         </td><td>all  (a catch-all for cross and multiple denpendencies)</td>
</tr><tr>
<td>ref-gifi              </td><td>none, integrates with accounts-ledger</td>
</tr><tr>
<td>ref-unspsc            </td><td>none, integrates with categories</td>
</tr><tr>
<td>accounts-payroll      </td><td>accounts-ledger, contacts</td>
</tr><tr>
<td>inventory-control     </td><td>none</td>
</tr><tr>
<td>online-catalog        </td><td>none</td>
</tr><tr>
<td>shipping-tracking</td><td></td>
</tr></table>
<p>(see <a href="http://bitscafe.com/pub2/etp/development/packages-map" target="_blank">integrated packages map</a>)
</p>
<h3>
functions and procedures
</h3><p>
lc_number_to_text proc is made from the the SL Num2text procedure which has localized cases in the locale directories, and the default Num2text.pm in sql-ledger/SL/
</p>
<h3>
SQL
</h3><p>
The Oracle SQL will be added after the PG SQL has settled a bit.
</p><p>Some of the SQL has been changed to the OpenACS standards. See http://openacs.org/doc/current/eng-standards-plsql.html and http://openacs.org/wiki
</p><pre>
for Postgresql:

INT changed to INTEGER
some of the TEXT types were changed to VARCHAR so that they get indexed
FLOAT changed to NUMERIC
</pre>

