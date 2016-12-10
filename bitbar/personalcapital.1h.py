#!/usr/local/bin/python
from personalcapital import PersonalCapital, RequireTwoFactorException, TwoFactorVerificationModeEnum
import json
import os.path

config_path = os.path.expanduser('~/.bitbar')
root_key = 'personalcapital'
session_key = 'session'

def get_config():
    with open(config_path) as data_file:
        return json.load(data_file)

def get_auth():
    auth = get_config()[root_key]
    return auth['email'], auth['password']

class PewCapital(PersonalCapital):
    def __init__(self):
        PersonalCapital.__init__(self)
        self.__session_file = config_path

    def load_session(self):
        cookies = get_config()[root_key][session_key]
        self.set_session(cookies)

    def save_session(self):
        existing_data = get_config()
        existing_data[root_key][session_key] = self.get_session()

        with open(self.__session_file, 'w') as data_file:
            data_file.write(json.dumps(existing_data, sort_keys=True, indent=4, separators=(',', ': ')))

def main():
    email, password = get_auth()
    pc = PewCapital()
    pc.load_session()

    try:
        pc.login(email, password)
    except RequireTwoFactorException:
        pc.two_factor_challenge(TwoFactorVerificationModeEnum.SMS)
        pc.two_factor_authenticate(TwoFactorVerificationModeEnum.SMS, raw_input('code: '))
        pc.authenticate_password(password)

    accounts_response = pc.fetch('/newaccount/getAccounts')

    pc.save_session()

    accounts = accounts_response.json()['spData']
    checking_accounts = filter(lambda account: account['accountTypeNew'] == 'CHECKING' and account['currentBalance'] > 0, accounts['accounts'])


    print('{:,.0f}'.format(accounts['networth']))
    print('---')
    for checking_account in checking_accounts:
        print('{0} {1:,.0f}'.format(checking_account['firmName'], checking_account['currentBalance']))

if __name__ == '__main__':
    main()