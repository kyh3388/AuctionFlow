<%@page contentType="text/html; charset=UTF-8" pageEncoding ="UTF-8"%>
<%@page import="jakarta.servlet.http.*"%>
<%@page import="coreframe.log.Logger"%>
<%@page import="coreframe.CoreFramework"%>
<%

// 현재 프로젝트 설정이 잘 적용되고 있는 지 확인하는 jsp

// 실제로 jakarta 로 적용되고 있는 지 확인
String jakartaServeltHttp = HttpServletRequest.class.getPackage().getName();
Logger.debug.println("Http Servlet : " + jakartaServeltHttp);

Package pkg = jakarta.servlet.jsp.jstl.core.LoopTagSupport.class.getPackage();
String jstlVer = pkg.getImplementationVersion();

request.setAttribute("javaVersion", Runtime.version());
request.setAttribute("tomcatVersion", application.getServerInfo());
request.setAttribute("servletVersion", application.getEffectiveMajorVersion() + "." + application.getEffectiveMinorVersion());
request.setAttribute("coreframeVersion", "CoreFramework(jakarta) " + CoreFramework.getInstance().getVersionInfo());
request.setAttribute("jstlVersion", jstlVer);
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>coreframe 6 poc</title>
</head>
<body>

<table style="border-collapse: collapse;">
	<tbody>
		<tr>
			<th>Java</th>
			<td>${javaVersion }</td>
		</tr>
		<tr>
			<th>Server</th>
			<td>${tomcatVersion }</td>
		</tr>
		<tr>
			<th>Servlet</th>
			<td>${servletVersion }</td>
			<!-- (web.xml &amp; eclipse > project facets > dynamic web module version) -->
		</tr>
		<tr>
			<th>CoreFramework</th>
			<td>${coreframeVersion }</td>
		</tr>
		<tr>
			<th>Tag Library (*.tld)</th>
			<td>3.0</td>
		</tr>
		<tr>
			<th>JSTL</th>
			<td>${jstlVersion }</td>
		</tr>
	</tbody>
</table>

</body>
</html>
