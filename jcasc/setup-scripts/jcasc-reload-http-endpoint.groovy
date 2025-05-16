/**
 * This script sets up the HTTP endpoint for JCasC configuration reload
 * To be placed in JENKINS_HOME/init.groovy.d/ to run during Jenkins startup
 */

import jenkins.model.Jenkins
import org.kohsuke.stapler.StaplerRequest
import org.kohsuke.stapler.StaplerResponse
import hudson.Extension
import hudson.model.RootAction
import io.jenkins.plugins.casc.ConfigurationAsCode
import java.util.logging.Logger

/**
 * Extension point that adds a "reload-jcasc" URL action to Jenkins
 * This endpoint allows for secure reloading of JCasC configuration
 * via HTTP request with appropriate authentication
 */
@Extension
class JCasConfigReloadAction implements RootAction {
    private static final Logger LOGGER = Logger.getLogger(JCasConfigReloadAction.class.getName())
    private final String RELOAD_TOKEN = System.getenv("CASC_RELOAD_TOKEN")
    
    @Override
    String getIconFileName() {
        return null // No UI element
    }
    
    @Override
    String getDisplayName() {
        return null // No UI element
    }
    
    @Override
    String getUrlName() {
        return "reload-jcasc" // This is the URL path: /reload-jcasc
    }
    
    /**
     * Handle HTTP GET requests
     */
    def doDynamic(StaplerRequest req, StaplerResponse rsp) {
        // Only POST method is allowed for security
        rsp.sendError(405, "Method not allowed. Use POST.")
    }
    
    /**
     * Handle HTTP POST requests
     */
    def doIndex(StaplerRequest req, StaplerResponse rsp) {
        // Only allow POST
        if (req.method != "POST") {
            rsp.sendError(405, "Method not allowed. Use POST.")
            return
        }
        
        // Check authentication token
        String token = req.getParameter("token")
        if (RELOAD_TOKEN == null || RELOAD_TOKEN.isEmpty()) {
            LOGGER.severe("CASC_RELOAD_TOKEN is not set. Configuration reload via HTTP is disabled.")
            rsp.sendError(500, "Configuration reload via HTTP is disabled. CASC_RELOAD_TOKEN not set.")
            return
        }
        
        if (token == null || !token.equals(RELOAD_TOKEN)) {
            LOGGER.warning("Unauthorized attempt to reload JCasC configuration")
            rsp.sendError(401, "Unauthorized")
            return
        }
        
        // Reload configuration
        try {
            LOGGER.info("Reloading JCasC configuration triggered by HTTP endpoint")
            ConfigurationAsCode.get().reload()
            rsp.setContentType("text/plain")
            rsp.getWriter().println("JCasC configuration successfully reloaded")
        } catch (Exception e) {
            LOGGER.severe("Failed to reload JCasC configuration: " + e.getMessage())
            rsp.sendError(500, "Failed to reload configuration: " + e.getMessage())
        }
    }
}