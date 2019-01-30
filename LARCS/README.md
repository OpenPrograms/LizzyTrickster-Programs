LARCS: Lizzy's Automated Railroad Control Suite
======

This is LARCS, more info to be put here later...


All network messages follow this default format:
- `LARCS, MESSAGE_ID, DATA, EXTRA_DATA`
  - `LARCS` Just starts the network message to allow for easy checking if running other stuff on ports LARCS uses
  - `MESSAGE_ID` The type of message being sent, check `lib/larcs/common.lua` for the "NetworkID" variables.
  - `DATA` Primary data for the network message. Pretty much all network messages will contain this.
  - `EXTRA_DATA` Extra data, like above but only occasionally used.