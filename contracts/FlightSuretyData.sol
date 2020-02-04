pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                    
    bool private operational = true;                                   

    struct Airline {
        string name;
        bool isRegistered;
        bool registrationFee;
    }

    mapping(address => Airline) airlines;
    uint256 public totalRegisteredAirlines;
    mapping(address => uint256) private authorizedCaller;

    struct Flight {
        uint statusCode;
        string flightCode;
        string origin;
        string destination;
        uint256 departureTime;
        uint ticketFee;
        address airlineAddress;
        mapping(address => bool) flightBookings;
        mapping(address => uint) flightiInsurances;
    }     
    mapping(bytes32 => Flight) public flights;                            
    bytes32[] public flightKeys;
    uint public totalFlightKeys = 0;
    
    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                 address genesisAirline
                                ) 
                                public 
    {
        authorizedCaller[msg.sender] = 1;
        contractOwner = msg.sender;
        airlines[msg.sender] = Airline({
                                     name: "Genesis Airline",
                                     isRegistered: true,
                                     registrationFee: true
        });
        
        airlines[genesisAirline].isRegistered = true;
        totalRegisteredAirlines = 1;

    }
    /********************************************************************************************/
    /*                                       EVENTS                                             */
    /********************************************************************************************/

    event receivedRegistrationFee(address fundAddress);

    event newAirlineRegistered(address newAirline,address airlineReferral);
    
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }


    modifier requireIsCallerAuthorized()
    {
        require(authorizedCaller[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external 
    {
        require(authorizedCaller[msg.sender] == 1, "Caller is not authorized");
        operational = mode;
    }

    function authorizeCaller
                            (
                                address callerAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedCaller[callerAddress] = 1;
    }

    function deauthorizeCaller
                            (
                                address callerAddress
                            )
                            external
                            requireContractOwner
    {
        delete authorizedCaller[callerAddress];
    }

    function isAuthorizedCaller (
                                 address caller
                                 ) 
                                 public 
                                 view  
                                 returns (uint256)
                                  {
        return authorizedCaller[caller]; 
    }

    function isAirline(
                               address addressAirline
                              )
                              external
                              view
                              returns (bool)
                              {                    
    return airlines[addressAirline].isRegistered;                                                   
    }

    function paidRegistration(
                               address airlineAddress
                               ) 
                               external
                               view 
                              returns (bool registrationFee)
    {
        registrationFee = airlines[airlineAddress].registrationFee;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */ 
    
    function registerAirline
                            (    
                                string name,
                                address newAirline,
                                address airlineReferral                              
                            )
                            external
                            requireIsOperational
    {
        require(!airlines[newAirline].isRegistered, "Airline is alredy registered.");
        require(airlines[airlineReferral].isRegistered, "Referral airline is not registered.");

        
        airlines[newAirline] = Airline({
                                     name: name,
                                     isRegistered: true,
                                     registrationFee: false
        });
        totalRegisteredAirlines = totalRegisteredAirlines.add(1);
        
        emit newAirlineRegistered(newAirline,airlineReferral);
    }

    function registerFlight
    (
        uint statusCode,
        string flightCode,
        string origin,
        string destination,
        uint256 departureTime,
        uint ticketFee,
        address airlineAddress
    )
    external
    requireIsOperational
    {
        require(departureTime > now, "Flight time must be later");
    
        Flight memory flight = Flight(
          statusCode,
          flightCode,
          origin,
          destination,
          departureTime,
          ticketFee,
          airlineAddress
        );

        bytes32 flightKey = getFlightKey
                           (
                            airlineAddress,
                            flightCode,
                            departureTime
                           );
                           
        flights[flightKey] = flight;

        totalFlightKeys = flightKeys.push(flightKey).sub(1);
        
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (                             
                            )
                            external
                            payable
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                pure
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            pure
    {
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                              address fundAddress  
                            )
                            public
                            requireIsOperational
                            payable
    {
        airlines[fundAddress].registrationFee = true;
        emit receivedRegistrationFee(fundAddress);
    }

    function getFlightKey
                        (
                            address airline,
                            string flightCode,
                            uint256 departureTime
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flightCode, departureTime));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        require(msg.data.length == 0,"Fallback function,data must be greater than Zero to proceed");
        fund(msg.sender);
    }


}
