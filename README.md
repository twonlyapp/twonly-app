# Connect

> Connect a zecure open-source instant-image sharing, full-featured AI app based on 5 blockchains. 

Actually there is no AI or Blockchain or any other dump hyped stuff included into this app.  The
purpose of this app is first off all to create a usable, good looking and important of all
end-to-end encrypted alternative to S[redacted]chat. As I love to schare images with friends but not
a strange company.

## Features

This app was started because of the three main features I missed out by popular alternatives.

### Three to rule them all.

1. Security by design: No one except your device can access your data.
2. Privacy by design: The server only knows your username and public key.
3. User-friendliness: Decide for your own :)

> "It's the combination that makes the difference. Only a combination of privacy, security and user-friendliness can make a application good. Focusing on just one of these three areas can mean that everyone loses out in the end." ~ Myself

### But there is even more!

4. Decentralized: Everyone can host an server. The usernames are like your email USERNAME@YOURSERVER
5. Simple to use: What is a Public key? If you don't know this it is okay you don't have to to use Connect!

> "Its like when S[redacted]chat, Signal and email had an baby" ~ Myself

## Roadmap

The development of this App has the following stages:

1. **Working POC**: As this is my first App ever the first step is to learn App development. During
this step I try everything I can do as a non experienced App developer to make working POC App which
is by design secure meaning while I learn new things I always try to think how this could be
attacked and how I could protect it. But as I have no experience at all I depend on libraries who
look secure. This step include:  

    1. Create a working POC and an private invitation code
    2. Test the POC with friends
    3. Improve and fix bugs
    4. Repeat steps 2. and 3. until I have a usable App

2. **Bug Bounty**: This is probably the most fun part. The GitHub Repository will become open-source
and I make public releases so others can [install](https://github.com/ImranR98/Obtainium) and test
the app as well. After I published the App the following steps will happen.
    1. I try to hack my own App using the free Android Hacking Course from
    [heytree.io](https://app.hextree.io/map/android/android-continent). And if I find something will
    create a nice write-up.
    2. Add the new invitation code "BUGBOUNTY" so reale smart people (not
    like me) can try to hack the app. And if they find something and create a small POC there is a
    small Bug Bounty of 50€.

3. **Pre-Releasing and Scaling**: If I ever come to this point the App will be first released on
[droidy-fy](https://droidify.eu.org/) to test on a larger scale.

4. **Release**: This will probably never happen, but if it will, I will release the App on Google
Play and maybe Apple App Store for a couple of €€ as this requires a paid developer account :/. The 
version on droid-fy will be free for ever to encourage people to switch to open source apps which.

5. **Becoming Rich**: I will add an ChatBot into the App. Then I rename the App into ConnectAI add
misleading advertisement on the website that the app is smart as it has an AI and then sell the app
for $7 trillion to become rich.

## Decentralized

The idea behind this idea is that the server does not know anything about the user. As the server 
is not able to read the messages but only see the receiver of it the only purpose is to forward 
the message. So like for emails the user can specify in his username to which server he belongs to.


The username is then build up with the following informations:

`username@fqdn:port`

The username is unique for the corresponding server. The second part contains the fully qualified
domain name where the server is reachable. It is also possible to specify a custom port. The 
default port are the HTTP and TLS ports. 


### Thoughts
When the user is adding another user they could exchange the servers public key which the user then
reports to their own home sever. The home server then can authenticate the other server.  But what
is the thread here, the server are not able to see the messages nor change it as the client does an
integrity check. An attacker could drop a messages and send an ACK as this is unauthenticated.

## Donating

As this is currently just a stupid project which does not work or serves a real use case even I
would not donate anything to it. But there is another cool way: If you are on the search for a really
cheap hosting provider which I use for my self for over 8 years you could use the following voucher
to get 5€ off `36nc15747855300` (contact me to get a 30% off voucher). I get 10% from the affiliate program which
helps me cover my hosting costs :)

## Self-hosting

It is possible to host the server yourself and then modify the server in your app.  But be aware it
is not planned to sync the different servers so you can only add people when their are on the same
server! As in my understanding this is not supported by the Signal protocol, but please proof me
wrong and at a PR :)

A possible idea could be to add multiple servers in app but this would then require multiple
parallel open websocket connection to check for new messages. As before if you want that feature
create a PR :)


## Bug-Bounty

This app offers a Bug Bounty as I really love the Idea of others hacking my app. Depending on the
criticality the bounty can go up to 50€ (more later when there are donation or I actually make some
money which I probably never will do :/).

## Credits

As this is my first Android app, I used different examples where I copied the code design decisions.
To give them credits and maybe help others they are listed below:

- [Database handling (model, provider and usage)](https://github.com/alextekartik/flutter_app_example/blob/master/notepad_sqflite/)