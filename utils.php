<?php
    /* ------------------------------------------------------------------------------------------ */
    abstract class chst {                       // challenge state
        const wrong   = -1;                     // wrong flag
        const correct = 1;                      // correct flag
        const solved  = 2;                      // already solved challenge
        const none    = 3;                      // flag not submitted
        const expired = 4;                      // flag expired
        const error   = -9;                     // error during submit
    }
    /* ------------------------------------------------------------------------------------------ */
    function prntusr()                          // print user's info at the top of the banner
    {
        $conn = dbconn();                       // connect to the DB server
        
        /* get current user's points */
        if( !($stmt = $conn->prepare("SELECT points FROM sC0r3__ WHERE uid=?")) ||
            ! $stmt->bind_param("i", $_SESSION['uid']) ||
            ! $stmt->execute() ||         
            ! $stmt->bind_result($points) ||
            ! $stmt->fetch() )
        {
            $stmt->close();                     // close prepared statement
            $conn->close();                     // close db connection
            die;                                // something went wrong
        }

        $conn->close();                         // close connection with the DB

        echo "<strong>Welcome $_SESSION[usr]! You have $points points.</strong></br>";
    }
    /* ------------------------------------------------------------------------------------------ */
    function gentok()                           // generate a random token to prevent CSRF
    {
        $_SESSION['lasttok'] = rand();          // generate something random

        return $_SESSION['lasttok'];            // and return it
    }
    /* ------------------------------------------------------------------------------------------ */
    function chktok( $token )                   // check if token is valid
    {
        // every time a form appears a different token is generated.
        // if we submit the token that we generated for that form, we're ok
        if( empty($token) || $_SESSION['lasttok'] != $token )
            return -1;                          // CSRF detected

        return 0;                               // we're ok
    }
    /* ------------------------------------------------------------------------------------------ */
    function htmlsafe( $str )                   // make $str safe for displaying to browser
    {
        return htmlentities( $str );            // that's enough for now
    }
    /* ------------------------------------------------------------------------------------------ */
    function intsafe( $int )                    // make sure that $int is an integer
    {   
        if( !is_numeric($int) )                 // if not a number
            return -1;                          // return error

        return intval( $int );                  // return integer part
    }
    /* ------------------------------------------------------------------------------------------ */
    function sqlsafe( $str )                    // make $str safe for sending to database
    {
        if( get_magic_quotes_gpc() ) 
            $str = stripslashes($str);          // apply stripslashes if magic_quotes_gpc is enabled
            
        // TODO: Fix this   
        // $str = mysql_real_escape_string($str);
        
        return $str;
    }
    /* ------------------------------------------------------------------------------------------ */
    function dbconn()                           // connect to the database server
    {
        // create connection
        $conn = new mysqli("127.0.0.1", "lowpriv", "chrysa", "cs527_ctf");
        
        if( $conn->connect_error )              // check connection state
            die("Connection failed: " . $conn->connect_error);

        return $conn;                           // return handle
    }
    /* ------------------------------------------------------------------------------------------ */
    function authusr( $usr, $pwd )              // authenticate a user
    {
        // log login attempt first
        if( ($fp = fopen('/var/log/web_login.log', 'a')) != NULL )
        {
            fprintf( $fp, "%s\t%s\t%s\t%s\n", 
                date('m/d/Y h:i:s a', time()), $_SERVER['REMOTE_ADDR'], $usr, $pwd );
            fclose( $fp );
        }

        
        $conn = dbconn();                       // connect to the DB server
        
        // simply call authusr() stored procedure
        // hash password before sending, to protect it against sniffing
        if( !($stmt = $conn->prepare("CALL authusr(?, ?)")) ||
            ! $stmt->bind_param("ss", $usr, sha1($pwd .'i$p0z5aL7')) || 
            ! $stmt->execute() ||                   
            ! $stmt->bind_result($uid) ||           
            ! $stmt->fetch()                    // fetch value; error if empty set returned
        ) {         
            $stmt->close();                     // close statement
            $conn->close();                     // close connection with the DB

            sleep( 1 );                         // a small delay to prevent brute force

            return -1;  // usr/pwd combination is incorrect or, something went wrong
        }
        
        $stmt->close();                         // close statement

        // authentication succeeded. Initialize session variables   
        $_SESSION["uid"] = $uid;                // get user id
        $_SESSION["usr"] = $usr;                // and username
                
        // get solved challenges of that user. We need this to mark the solved challenges.        
        // By keeping this information in sessions, we can avoid asking the webserver 
        // every time user visits the main page. This is not a very good approach as we 
        // may have consistency issues, but not in this project
        if( !($stmt = $conn->prepare("CALL getslvd(?)")) ||
            ! $stmt->bind_param("i", $_SESSION['uid']) ||
            ! $stmt->execute() ||
            ! $stmt->bind_result($cid, $slvd, $chng)
        ) {
            $stmt->close();                     // close statement
            $conn->close();                     // close connection with the DB
            return -1;                          // something went wrong
        }
        
        for( $i=1; $stmt->fetch(); $i=$i+1 )    // start fetching records
        {
            // find challenge category name. MSNibble indicates category:
            switch( ($cid & 0x0f000000) >> 24 ) // 2nd - MSNibble
            {
                case 1 : $name = "Reversing"; break;
                case 2 : $name = "Pwn"; break;
                case 3 : $name = "Web"; break;
                case 4 : $name = "Misc"; break;
                case 5 : $name = "Real"; break;
                default: $name = "Unknown";
            }

            if( $chng == 1 ) $i = 1;            // if we changed category, clear iterator

            $_SESSION['chal'][$cid] = array(    // set session info for that challenge
                'slvd'  => $slvd,
                'chng'  => $chng,
                'name'  => $name,
                'id'    => $i
            );
        }

        $stmt->close();                         // close statement
        $conn->close();                         // close connection with the DB

        return $uid;                            // return user id
    }   
    /* ------------------------------------------------------------------------------------------ */
    function authflag( $cid, $flag )            // authenticate a flag
    {
        $conn = dbconn();                       // connect to the DB server
                        
        if( !($stmt = $conn->prepare("CALL authflag(?, ?, ?)")) ||
            ! $stmt->bind_param("iis", $_SESSION['uid'], $cid, sha1($flag . 'i$p0z5aL7')) ||    
            ! $stmt->execute()  ||
            ! $stmt->bind_result($succ) ||
            ! $stmt->fetch()                    // fetch first value: 0 or 1
        ) { 
            $stmt->close();                     // close statement
            $conn->close();                     // close connection with the DB 
            return chst::error;                 // something went wrong 
        }

        if( $succ == 0 )                        // if we got 0, flag was wrong
        {
             $retn = chst::wrong;               
             sleep( 1 );                        // a small delay to prevent brute force
        }
        else if( $succ == 1 )                   // if we got 1, flag is correct
        {
            $_SESSION['chal'][$cid]['slvd'] = 1;// mark as solved
            
            // now, we have to check if it's already solved
            if( $stmt->fetch() )                // fetch 2nd row
            {
                // if 2nd column is 1, flag already exists
                if( $succ == 1 ) $retn = chst::solved;
                else $retn = chst::correct;     // correct flag, finally!
                
            } 
            else $retn = chst::error;           // something went wrong 
        }
        else if( $succ == -2 )                  // if we got -2, flag expired
        {
            $retn = chst::expired;              // flag expired
        }

        else $retn = chst::error;               // we have and error here
        
        $stmt->close();                         // close statement
        $conn->close();                         // close connection with the DB 

        return $retn;                           // 
    }
    /* ------------------------------------------------------------------------------------------ */
    function prntnavbar()                       // print navigation bar
    {
        ?>
          <div class="container">
            <div class="navbar navbar-default navbar-fixed-top">
              <div class="container">
                <div class="navbar-header">
                  <i class="glyphicon glyphicon-flag" style="color:#00a700"></i>
                  <font color="#00a700">CS527</font>
                </div>
                
                <div class="navbar-collapse collapse" id="navbar-main">
                  <ul class="nav navbar-nav">
                    <li><a href="dashboard.php"> Challenges</a></li>
                    <li><a href="rank.php"     > Scoreboard</a></li>
                    <li><a href="about.php"    > About     </a></li>
                  </ul>              
                  
                  <a href="logout.php">
                    <ul class="nav navbar-nav pull-right" style="margin-top:5px;">
                      <li>
                        <button type="button" class="btn btn-logout">
                          <i class="glyphicon glyphicon-circle-arrow-right"></i> 
                          Logout
                        </button>         
                      </li>
                    </ul>
                  </a>
                </div>
              </div>
            </div>
          </div>
         <?php
    }
    /* ------------------------------------------------------------------------------------------ */
    function prntfooter()                       // print page footer
    {
        ?>      
            <footer>
                <div class="row">
                    <div class="col-md-6 col-sm-6 col-xs-6"></div>
                    <div class="col-md-6 col-sm-6 col-xs-6 text-right">
                        &copy; <a href="https://twitter.com/ispo__" target="_blank">ispo</a> 2016
                    </div>
                </div>
            </footer>
        <?php
    }
    /* ------------------------------------------------------------------------------------------ */
?>
