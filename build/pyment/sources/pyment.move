
/// Module: pyment
module pyment::pyment{
    use std::string::{String};
    use sui::balance::{Balance,zero};
    use sui::sui::SUI;
    use sui::coin::{Coin,split, put,take};
    //define errors
    const ONLYOWNERISALOWED:u64=0;
    const SERVICENOTAVAIALBLE:u64=1;
    const INSUFFICIENTBALANCE:u64=2;
    public struct PayEasy has key,store{
        id:UID,
        payeasyid:ID,
        nameofcompany:String,
        services:vector<Service>,
        balance:Balance<SUI>,

    }

    public struct Service has store{
        id:u64,
        name:String,
        description:String,
        amounttobepaid:u64,
        
    }


    //admin capabilities
    public struct OwnerCap has key{
        id:UID,
        payeasyid:ID
    }
    //integrate payeasy into your daap
    public entry fun integrate_pay_easy(nameofcompany:String,ctx:&mut TxContext){

        //genrate uniques ids
        let id=object::new(ctx);
        //genarete payid
        let payeasyid=object::uid_to_inner(&id);

        //register your comapny to use pay easy system
         
        let new_company=PayEasy{
            id,
            payeasyid,
            nameofcompany,
            services:vector::empty(),
            balance:zero<SUI>()
        };

        //transfer the capablities to the owner of the company

         transfer::transfer(OwnerCap {
         id: object::new(ctx),
          payeasyid,
    }, tx_context::sender(ctx));
        //share your company

        transfer::share_object(new_company);
    }


    //add the services the comp[any is offering the amount charging of the service package


    public entry fun add_services_of_company(company:&mut PayEasy,owner:&OwnerCap,name:String,description:String,amount:u64,ctx:&mut TxContext){

        //verify to make sure its only the owner integrating the payeasy can perform the action

        assert!(owner.payeasyid==company.payeasyid,ONLYOWNERISALOWED);

        //get the length of services inorder to create  a unique id

        let id:u64=company.services.length();

        //create a new service
        let newservice=Service{
            id,
            name,
            description,
            amounttobepaid:amount
        };

        //add new service to company

        company.services.push_back(newservice);
    }

    //users pay for the services and get the receipt

    public entry fun pay_for_service(company:&mut PayEasy,serviceid:u64,amount:&mut Coin<SUI>,ctx:&mut TxContext){

        //verify the the service user is trying to pay is available

        assert!(company.services.length()>=serviceid,SERVICENOTAVAIALBLE);
        //verify the user has sufficient amount to perform the transaction

        assert!(company.services[serviceid].amounttobepaid>=amount.value(),INSUFFICIENTBALANCE);

        let amounttopay=company.services[serviceid].amounttobepaid;

        let pay=amount.split(amounttopay,ctx);
         
          put(&mut company.balance, pay); 


    }

    //owner withdraw all amount available

    //owner withdraw sepceifc amount

    //get services offred by the company
    //owener withdraw all funds
 public entry fun withdraw_all_funds(
        owner: &OwnerCap,         
        company: &mut PayEasy,
        recipient:address,
        ctx: &mut TxContext,
    ) {
        //ensure its the owner performing the action
        assert!(owner.payeasyid==company.payeasyid,ONLYOWNERISALOWED);

        
        let allamount=company.balance.value();
        
        let takeall = take(&mut company.balance, allamount, ctx); 
        transfer::public_transfer(takeall, recipient);  
       
    }

  //owener widthradw specific funds
 
   public entry fun withdraw_specific_funds(
        owner: &OwnerCap,      
        company: &mut PayEasy,
        amount:u64,
        recipient:address,
         ctx: &mut TxContext,
    ) {

        //verify amount is sufficient
      assert!(amount > 0 && amount <= company.balance.value(), INSUFFICIENTBALANCE);

      //ensure its the owener performing the action

        assert!(owner.payeasyid==company.payeasyid,ONLYOWNERISALOWED);

        let balance=company.balance.value();
        
        let takeamount = take(&mut company.balance, amount, ctx);
        transfer::public_transfer(takeamount, recipient);
       
        
    }

}

