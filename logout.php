<?php 
/* -------------------------------------------------------------------------------- */
    session_start();                        // start session

    if( isset( $_SESSION['uid'] ) ) {       // already logged in?
    
    	session_unset();					// remove all session variables
		session_destroy();					// destroy the session   
    }
	
   	header('Location: index.php');  		// redirect

   	echo "bye bye telnet fan ;)\n";			// a message for telnet fans :P
/* -------------------------------------------------------------------------------- */
?>
