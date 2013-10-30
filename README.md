DCModel
=======

DCModel is an lightweight and simple abstraction of core data APIs and fully asynchronous for both iOS and Mac OSX. It borrows from active record (Ruby on Rails, anyone!?) syntax to make core data interaction fun and easy. It also adds primary key validation to your objects to avoid duplicates. I know, your brain just exploded. To the examples!

# Examples #
First we create a subclass of NSManagedObject as usual, but we also import DCModel.

```objective-c
	#import "DCModel.h"

	@interface User : NSManagedObject

	@property(nonatomic,copy)NSString *name;
	@property(nonatomic,copy)NSString *firstName;
	@property(nonatomic,copy)NSString *lastName;
	@property(nonatomic,strong)NSNumber *age;
	@property(nonatomic,strong)NSNumber *employed;

	@end
```
Next for the commands:
### Create/Save ###
Create an new object and save it

```objective-c
User *john = [User newObject];
john.name = @"John";
john.firstName = @"John";
john.lastName = @"Doe";
john.age = @22;
[john saveOrUpdate:^(id item){
    NSLog(@"successfully saved %@",[item name]);
}failure:^(NSError* error){
    NSLog(@"got an error, that is no good: %@",[error localizedDescription]);
}];
```

### Find/Delete ###
find and delete all the johns

```objective-c
[User where:@"name == John" success:^(id items){
	[User destroyObjects:items success:^{
		NSLog(@"deleted all the John's!");
	}failure:^(NSError* error){
		NSLog(@"got an error, that is no good: %@",[error localizedDescription]);
}];
```
### find/fetch ###
There are several search methods to make finding what you need 

```objective-c 
[User all:^(NSArray *items){ 
    for(User* user in items)
        NSLog(@"User name: %@ age: %@",user.name,user.age);
}];
```

It is important that we did all of this completely asynchronously and thread safe. No more headache of trying to manage a coreData object context from the a background thread and made sure your not deadlocking in the process with a clean syntax. You just get to focus on making an awesome app.
	
# Primary Key Validation #

Ok, so now I am sure you want to know about the Primary key validation I mentioned. Well here it is:
	
	//add this to your implemention file of your NSManagedObject subclass (User.m in our example)
	//return the property name of the key you want to be primary.
	+(NSString*)primaryKey
	{
	    return @"name";
	}
Done. Now anytime you save an object, it will validate to ensure that the object does not exist before adding it in. 

# Requirements/Dependencies  #

The CoreData frame work is required.

# Install #

The recommended approach for installing DCModel is via the CocoaPods package manager, as it provides flexible dependency management and dead simple installation.

via CocoaPods

Install CocoaPods if not already available:

	$ [sudo] gem install cocoapods
	$ pod setup
Change to the directory of your Xcode project, and Create and Edit your Podfile and add DCModel:

	$ cd /path/to/MyProject
	$ touch Podfile
	$ edit Podfile
	platform :ios, '5.0' 
	# Or platform :osx, '10.7'
	pod 'DCModel'

Install into your project:

	$ pod install
	
Open your project in Xcode from the .xcworkspace file (not the usual project file)

# License #

DCModel is license under the Apache License.

# Contact #

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam