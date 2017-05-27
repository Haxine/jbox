# -*- coding: utf-8 -*-
import random, string
from itsdangerous import SignatureExpired, BadSignature, TimedJSONWebSignatureSerializer as Serializer
from flask import current_app, g
from passlib.apps import custom_app_context as pwd_context
from flask_httpauth import HTTPBasicAuth
from sqlalchemy.exc import IntegrityError
from jbox import db
from flask_login import UserMixin
from . import login_manager

httpauth = HTTPBasicAuth()


class Developer(UserMixin, db.Model):
    __tablename__ = 'developers'
    id = db.Column(db.Integer, primary_key=True)
    dev_key = db.Column(db.String(40), unique=True, index=True)
    platform = db.Column(db.String(50))
    platform_id = db.Column(db.String(40), unique=True)
    username = db.Column(db.String(150), index=True, default='')
    email = db.Column(db.String(50), default='')
    confirmed = db.Column(db.Boolean, default=False)
    description = db.Column(db.String(150), default='')
    avatar = db.Column(db.String(150))
    integrations = db.relationship('Integration', backref='developer')
    channels = db.relationship('Channel', primaryjoin='Developer.id==Channel.developer_id', backref='developer')
    authorizations = db.relationship('Authorization', backref='developer')

    def __repr__(self):
        return '<Developer %r>' % self.dev_key

    def verify_developer(self, platform_id):
        return pwd_context.verify(platform_id, self.platform_id)

    def generate_confirmation_token(self, expiration=3600):
        s = Serializer(current_app.config['SECRET_KEY'], expiration)
        return s.dumps({'confirm': self.id})

    @staticmethod
    def confirm(token):
        s = Serializer(current_app.config['SECRET_KEY'])
        try:
            data = s.loads(token)
        except SignatureExpired:
            return None
        except BadSignature:
            return None
        developer = Developer.query.get(data['confirm'])
        return developer

    def insert_to_db(self):
        db.session.add(self)
        try:
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            b = False
            while b == False:
                user = Developer.query.filter_by(dev_key=self.dev_key).first()
                if user is None:
                    user = Developer.query.filter_by(platform_id=self.platform_id).first()
                    if user is not None:
                        self.platform_id = generate_platform_id()
                        db.session.add(self)
                        try:
                            db.session.commit()
                            b = True
                        except IntegrityError:
                            db.session.rollback()
                            b = False
                else:
                    self.dev_key = generate_dev_key()
                    db.session.add(self)
                    try:
                        db.session.commit()
                        b = True
                    except IntegrityError:
                        db.session.rollback()
                        b = False
        return True


@login_manager.user_loader
def developer_loader(platform, platform_id):
    developer = Developer.query.filter_by(platform=platform,platform_id=platform_id).first()
    return developer


@login_manager.request_loader
def request_loader(request):
    platform = request.form.get("platform")
    platform_id = request.form.get("platform_id")
    developer = Developer.query.filter_by(platform=platform, platform_id=platform_id).first()
    return developer


@httpauth.verify_password
def verify_developer(platform_or_token, platform_id):
    developer = Developer.confirm(platform_or_token)
    if not developer:
        developer = Developer.query.filter_by(platform=platform_or_token, platform_id=platform_id).first()
        if not developer:
            return False
    g.developer = developer
    return True


class Integration(db.Model):
    __tablename__ = 'integrations'
    id = db.Column(db.Integer, primary_key=True)
    integration_id = db.Column(db.String(40), unique=True)
    name = db.Column(db.String(100), default='')
    description = db.Column(db.String(150), default='')
    icon = db.Column(db.String(150))
    token = db.Column(db.String(150))
    type = db.Column(db.String(50), default='custom')
    owner = db.Column(db.String(100))
    developer_id = db.Column(db.Integer, db.ForeignKey('developers.id'))
    channel_id = db.Column(db.Integer, db.ForeignKey('channels.id'))
    githubs = db.relationship('GitHub', backref='integration')

    def __repr__(self):
        return '<Integration %r>' % self.integration_id

    def insert_to_db(self):
        db.session.add(self)
        try:
            db.session.commit()
        except IntegrityError:
            db.session.rollback()
            flag = False
            while flag == False:
                integration = Integration.query.filter_by(integration_id=self.integration_id).first()
                if integration is not None:
                    self.integration_id = generate_integration_id()
                    db.session.add(self)
                    try:
                        db.session.commit()
                        flag = True
                    except IntegrityError:
                        db.session.rollback()
                        flag = False
                else:
                    flag = True
        return True


class GitHub(db.Model):
    __tablename__ = 'githubs'
    id = db.Column(db.Integer, primary_key=True)
    integration_id = db.Column(db.Integer, db.ForeignKey('integrations.id'))
    repository = db.Column(db.String(150))
    hook_id = db.Column(db.Integer)


class Channel(db.Model):
    __tablename__ = 'channels'
    id = db.Column(db.Integer, primary_key=True)
    developer_id = db.Column(db.Integer, db.ForeignKey('developers.id'))
    channel = db.Column(db.String(150))
    integrations = db.relationship('Integration', backref='channel')

    def __repr__(self):
        return '<Channel %r>' % self.channel


class Authorization(db.Model):
    __tablename__ = 'authorizations'
    id = db.Column(db.Integer, primary_key=True)
    oauth_token = db.Column(db.String(150))
    type = db.Column(db.String(50))
    developer_id = db.Column(db.Integer, db.ForeignKey('developers.id'))


@login_manager.user_loader
def load_user(developer_id):
    return Developer.query.get(int(developer_id))


def generate_dev_key():
    dev_key = ''.join([(string.ascii_letters+string.digits)[x] for x in random.sample(range(0, 62), 20)])
    return dev_key


def generate_platform_id():
    platform_id = ''.join([(string.ascii_letters+string.digits)[x] for x in random.sample(range(0, 62), 10)])
    return platform_id


def generate_integration_id():
    integration_id = ''.join([(string.ascii_letters+string.digits)[x] for x in random.sample(range(0, 62), 15)])
    return integration_id


def generate_auth_token():
    token = ''.join([(string.ascii_letters + string.digits)[x] for x in random.sample(range(0, 62), 10)])
    return token


