
<!DOCTYPE html>
<html lang="en">
<!--====================================================================================================-->
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport"              content="width=device-width, initial-scale=1">
  <meta name="description"           content="CS527 Software Security">
  <meta name="author"                content="ispo">

  <!-- our CSS: Bootstrap and our customization -->
  <link href="css/bootstrap.min.css" rel="stylesheet">
  <link href="css/custom.css"        rel="stylesheet">
  <link href="favicon.ico"           rel="icon">

  <title>CS527 Software Security</title>
</head>
<!--====================================================================================================-->
<body>
    <?php
    /* -------------------------------------------------------------------------------- */
        require( 'utils.php' );                 // import core security functions

        session_start();                        // start session

        if( !isset( $_SESSION['uid'] ) ) {      // not logged in?
            header('Location: index.php');      // redirect
            exit;                               // don't forget this!
        }

        prntnavbar();                           // print navigation bar
    /* -------------------------------------------------------------------------------- */
    ?>

  <div class="container">
    <div class="page-body jumbotron col-lg-12 col-md-7 col-sm-6">
      <!-- hall of fame -->
      <legend><h2>* * * Hall Of Fame * * *</h2></legend>
      Here there's the list of users who found security related issues in the website:
      <br/><br/>
      <ul class="list">
      <li><b>donut</b> got 300 points for being first who solved a "broken" challenge</li>
	  <li><b>Minion</b> got 300 points for finding exploits from other users in .bash_history</li>
      <li>...</li>
      </ul>


      <!-- Challenge Updates  -->
      <legend><h2>Challenge Updates</h2></legend>
      Here are any updates related to the challenges.
      <br/><br/>
      <ul class="list">
      <li>Jan 29th: Challenge <b>easyre_2</b> was broken. It's fixed now.</li>
      <li>Jan 31th: Challenge <b>key permutation</b> has not an 1-1 mapping. Thus multiple flags are allowed. However you can easily prune many solutions because you know that the flag will be a sentence. Charset is [a-zA-Z0-9_] plus 2 brackets {}. This makes challenge a little bit harder, so I updated challenge points to 800.</li>
      <li>Apr 16th: Challenge <b>SQL filters #2</b> was broken. It's fixed now.</li>
      <li>Apr 16th: Challenge <b>Overflow Me</b> updated. It's easier to exploit it now.</li>
      <li>Apr 16th: Challenge <b>FSA</b> has NX (DEP) disabled. Exploit is easier now.</li>
      <li>...</li>
      </ul>

      <!-- question's part -->
      <legend><h2>Questions</h2></legend>
      For any questions/issues/concerns about the challenges you can ask on:

      <ul class="list">
              <li>Piazza</li>
              <li>IRC: #cs527ctf on freenode</li>
            </ul>

            For any issues beyond the challenges, you can contact
      <i><a href="images/mailme.jpg">admin</a></i>
      <i class="glyphicon glyphicon-heart" style="color:#00a700"></i>
      <i class="glyphicon glyphicon-heart" style="color:#00a700"></i>
      <i class="glyphicon glyphicon-heart" style="color:#00a700"></i>

      <!-- scoring formula -->
      <legend><h2>Score Points</h2></legend>

        Every challenge has an initial number of points, based on its difficulty. However the number
        of points decreases every time that someone solves it. Furthermore all previous solvers,
        lose some points too. For instance if a challenge gets 100 points, the 1st student who successfully
        solves it, gets 100 points.
        </br>
        When the 2nd student solves it, 1st solver gets 90 points and 2nd gets 86.</br>
        When the 3rd student solves it, 1st solver gets 86 points, 2nd gets 80 and 3rd gets 76.</br>
        etc.</br></br>
        Below is the formula that gives you the number of points based on the initial points and the
        number of solves:
        </br>
        <ul class="list">
          <li>points = MAX(initial_points - SQRT((solvers-1)*initial_points*ord_i, initial_points/2)</li>
        </ul>

        </br>
        NOTE: You should keep writeups for the challenges you solve. They will be useful for the next challenges

        <!-- game rules -->
        <legend><h2>Rules</h2></legend>
        As in every game, there are some rules. Flag trading is a problem in all Jeopardy-style
        CTFs. Some challenges are username-specific but most of them have constant flags. It's
        academic dishonesty to trade flags. Furthermore for every flag you trade you lose points!
        </br>
        </br>
        Apart from that, there should be some rules for not attacking the server(s) and the other
        users.
        </br>
        Attacking the network is not part of the game. We put our efforts at the application level
        and the network layer is not our responsibility.
        </br></br>

        However, <strong>extra points</strong> will be given for those who will find security-related
        issues to the network.

        <!-- and finally, acknowledgements -->
        <legend><h2>Acknowledgements</h2></legend>
        Finally, I'd like to thank some people that helped me with this site:
        <ul class="list">
          <li>Daniele Midi</li>
          <li>Craig West</li>
          <li>....</li>
        </ul>
                    </br>

        <div class="col-lg-6" >
          <a href="http://hexhive.cs.purdue.edu/" target="_blank">
            <img class="partner" src="images/HexHive_logo.png"
                 height="100" data-toggle="tooltip" data-placement="bottom"
                 title="HexHive Systems Security group">
          </a>
        </div>

        <div class="col-lg-6" >
          <a href="https://b01lers.net/" target="_blank">
            <img class="partner" src="https://b01lers.net/static/B01lers/logo_full.png"
                 height="100" data-toggle="tooltip" data-placement="bottom"
                 title="b01lers ctf team">
          </a>
        </div>

    </div> <!-- jumbotron -->

    <?php prntfooter(); ?>

  </div> <!-- container -->
</body>
<!--====================================================================================================-->
</html>
