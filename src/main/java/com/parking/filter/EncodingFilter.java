package com.parking.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public class EncodingFilter implements Filter {

    private String encoding = "UTF-8";

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        String param = filterConfig.getInitParameter("encoding");
        if (param != null && !param.isEmpty()) {
            encoding = param;
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        request.setCharacterEncoding(encoding);
        response.setCharacterEncoding(encoding);
        response.setContentType("text/html;charset=" + encoding);

        if (response instanceof HttpServletResponse) {
            ((HttpServletResponse) response).setHeader("Access-Control-Allow-Origin", "*");
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}