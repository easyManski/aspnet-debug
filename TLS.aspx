<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Reflection" %>
<%@ Import Namespace="System.Runtime.Versioning" %>
<%@ Import Namespace="System.Security.AccessControl" %>
<%@ Import Namespace="Microsoft.Win32" %>
<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>TLS Tests</title>
    <style type="text/css">
        body {
            font-family: Consolas, monospace;
        }

        table, td, th {
            border: 1px solid gray;
            margin: 0;
            padding: 5px;
            border-collapse: collapse;
        }

        th {
            background-color: lightgray;
        }

        .good {
            background-color: lightgreen;
        }

        .bad {
            background-color: red;
        }

        .warn {
            background-color: orange;
        }

        .highlight {
            background-color: lightyellow;
            font-weight: bold;
        }
    </style>
</head>
<body>

    <% if (ServicePointManager.SecurityProtocol == SecurityProtocolType.SystemDefault)
        {
%>
    <h1 class="good">Application is using SystemDefault TLS protocols</h1>
    <%}
        else
        { %>
    <h1 class="bad">Application is not using SystemDefault TLS protocols</h1>
    <h2 class="bad">Protocols in use: <%= ServicePointManager.SecurityProtocol %></h2>
    <%} %>
    <%
        bool switchSetDontEnableSchUseStrongCrypto;
        bool switchSetDontEnableSystemDefaultTlsVersions;
        var switchDontEnableSchUseStrongCrypto = AppContext.TryGetSwitch("Switch.System.Net.DontEnableSchUseStrongCrypto", out switchSetDontEnableSchUseStrongCrypto);
        var switchDontEnableSystemDefaultTlsVersions = AppContext.TryGetSwitch("Switch.System.Net.DontEnableSystemDefaultTlsVersions", out switchSetDontEnableSystemDefaultTlsVersions);


        var globalConfigReadInt = Type.GetType("System.Net.RegistryConfiguration, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089").GetMethod("GlobalConfigReadInt");
        var registrySchUseStrongCrypto = (int)globalConfigReadInt.Invoke(null, new object[] { "SchUseStrongCrypto", int.MaxValue });
        var registrySystemDefaultTlsVersions = (int)globalConfigReadInt.Invoke(null, new object[] { "SystemDefaultTlsVersions", int.MaxValue });

        var registryKey = Registry.LocalMachine.OpenSubKey("SOFTWARE\\Microsoft\\.NETFramework\\v" + Environment.Version.ToString(3));

        var disableStrongCrypto = (bool)typeof(ServicePointManager).GetProperty("DisableStrongCrypto", BindingFlags.NonPublic | BindingFlags.Static).GetValue(null);
        var disableSystemDefaultTlsVersions = (bool)typeof(ServicePointManager).GetProperty("DisableSystemDefaultTlsVersions", BindingFlags.NonPublic | BindingFlags.Static).GetValue(null);
        var defaultSslProtocols = typeof(ServicePointManager).GetProperty("DefaultSslProtocols", BindingFlags.NonPublic | BindingFlags.Static).GetValue(null);

        var CheckRegistryValueKind = new Func<string, string>(name =>
        {
            try
            {
                var kind = registryKey.GetValueKind(name);
                if (kind != RegistryValueKind.DWord)
                {
                    return "Value is " + kind + " but must be DWORD";
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        });
    %>

    <table>
        <tr>
            <th>Setting</th>
            <th>Value</th>
            <th>Triage</th>
        </tr>
        <tr>
            <td>TargetFramework (GetExecutingAssembly)</td>
            <td><%
                    var targetFrameworkAttribute = Assembly.GetExecutingAssembly()
                        .GetCustomAttributes(typeof(TargetFrameworkAttribute), false)
                        .SingleOrDefault() as TargetFrameworkAttribute;

                    Response.Write(targetFrameworkAttribute.FrameworkName);
            %></td>
        </tr>
        <tr class="<%= switchDontEnableSchUseStrongCrypto ? "bad" : string.Empty %>">
            <td>AppContextSwitch.DontEnableSchUseStrongCrypto</td>
            <td><%= switchDontEnableSchUseStrongCrypto %></td>
            <td><%= switchSetDontEnableSchUseStrongCrypto ? "Strong crypto disabled" : "ok" %></td>
        </tr>
        <tr class="<%= registrySchUseStrongCrypto != 1 ? "warn" : string.Empty %>">
            <td>RegistryConfiguration.GlobalConfigReadInt("SchUseStrongCrypto")</td>
            <td><%= registrySchUseStrongCrypto == int.MaxValue ? "(not configured)" : registrySchUseStrongCrypto.ToString() %></td>
        </tr>
        <tr>
            <td>HKLM:\SOFTWARE\Microsoft\.NETFramework\v<%= Environment.Version.ToString(3) %>\SchUseStrongCrypto</td>
            <td><%= registryKey.GetValue("SchUseStrongCrypto") %></td>
            <td><%= CheckRegistryValueKind("SchUseStrongCrypto") %></td>
        </tr>
        <tr>
            <td>ServicePointManager.DisableStrongCrypto</td>
            <td><%= disableStrongCrypto %></td>
            <td><%= switchDontEnableSchUseStrongCrypto ? "Disabled by AppContextSwitch" :
                        registrySchUseStrongCrypto != 1 ? "SchUseStrongCrypto not set in Registry" : string.Empty %></td>
        </tr>
        <tr class="<%= switchDontEnableSystemDefaultTlsVersions ? "bad" : string.Empty %>">
            <td>AppContextSwitch.DontEnableSystemDefaultTlsVersions</td>
            <td><%= switchSetDontEnableSystemDefaultTlsVersions %></td>
            <td><%= switchDontEnableSystemDefaultTlsVersions ? "SystemDefault disabled" : "ok" %></td>
        </tr>
        <tr class="<%= registrySystemDefaultTlsVersions != 1 ? "warn" : string.Empty %>">
            <td>RegistryConfiguration.GlobalConfigReadInt("SystemDefaultTlsVersions")</td>
            <td><%= registrySystemDefaultTlsVersions == int.MaxValue ? "(not configured)" : registrySystemDefaultTlsVersions.ToString() %></td>
        </tr>
        <tr>
            <td>HKLM:\SOFTWARE\Microsoft\.NETFramework\v<%= Environment.Version.ToString(3) %>\SystemDefaultTlsVersions</td>
            <td><%= registryKey.GetValue("SystemDefaultTlsVersions") %></td>
            <td><%= CheckRegistryValueKind("SystemDefaultTlsVersions") %></td>
        </tr>
        <tr>
            <td>ServicePointManager.DisableSystemDefaultTlsVersions</td>
            <td><%= disableSystemDefaultTlsVersions %></td>
            <td><%= switchDontEnableSystemDefaultTlsVersions ? "Disabled by AppContextSwitch" : 
                        registrySystemDefaultTlsVersions != 1 ? "SystemDefaultTlsVersions not set in Registry" : string.Empty %></td>
        </tr>
        <tr>
            <td>ServicePointManager.DefaultSslProtocols</td>
            <td><%= defaultSslProtocols %> &rarr; <%= (SecurityProtocolType)defaultSslProtocols %></td>
            <td><%
                    if (disableSystemDefaultTlsVersions)
                        if (disableStrongCrypto)
                            Response.Write("SystemDefaultTlsVersions disabled and StrongCrypto disabled");
                        else
                            Response.Write("SystemDefaultTlsVersions disabled and StrongCrypto enabled");
                    else
                        Response.Write("SystemDefaultTlsVersions enabled");
            %></td>
        </tr>
        <tr class="highlight">
            <td>ServicePointManager.SecurityProtocol</td>
            <td><%= ServicePointManager.SecurityProtocol %></td>
        </tr>
    </table>

    <hr />

    <h3>Typical configurations</h3>
    If you see a value for ServicePointManager.SecurityProtocol above other than one of those in the table below, the application may be overriding the configuration.  Search the code for references to ServicePointManager.
    <table>
        <tr>
            <th>SchUseStrongCrypto</th>
            <th>SystemDefaultTlsVersions</th>
            <th>Security Protocols</th>
        </tr>
        <tr>
            <td>unset</td>
            <td>unset</td>
            <td>Ssl3, Tls </td>
        </tr>
        <tr>
            <td>unset</td>
            <td>0</td>
            <td>Ssl3, Tls</td>
        </tr>
        <tr>
            <td>0</td>
            <td>unset</td>
            <td>Ssl3, Tls</td>
        </tr>
        <tr>
            <td>0</td>
            <td>0</td>
            <td>Ssl3, Tls</td>
        </tr>
        <tr>
            <td>1</td>
            <td>unset</td>
            <td>Tls, Tls11, Tls12, Tls13 </td>
        </tr>
        <tr>
            <td>1</td>
            <td>0</td>
            <td>Tls, Tls11, Tls12, Tls13</td>
        </tr>
        <tr>
            <td>unset</td>
            <td>1</td>
            <td>SystemDefault</td>
        </tr>
        <tr>
            <td>0</td>
            <td>1</td>
            <td>SystemDefault</td>
        </tr>
        <tr>
            <td>1</td>
            <td>1</td>
            <td>SystemDefault</td>
        </tr>
    </table>
</body>

</html>
