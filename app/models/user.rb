# frozen_string_literal: true
require 'net/ldap'

class User < ActiveRecord::Base
  include Linkable

  has_many :reservations, foreign_key: 'reserver_id', dependent: :destroy
  has_and_belongs_to_many :requirements,
                          class_name: 'Requirement',
                          association_foreign_key: 'requirement_id',
                          join_table: 'users_requirements'

  attr_accessor :full_query, :created_by_admin, :user_type, :csv_import

  validates :username,    presence: true,
                          uniqueness: true
  validates :first_name,
            :last_name,
            :affiliation, presence: true
  validates :phone, presence: true,
                    format: { with: %r{\A[0-9\+\/\(\)\s\-]*\z} },
                    length: { minimum: 10 },
                    unless: ->(u) { u.skip_phone_validation? }
  validates :email,
            presence: true, uniqueness: true,
            format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i }

  validates :nickname,    format:      { with: /\A[^0-9`!@#\$%\^&*+_=]+\z/ },
                          allow_blank: true
  validates :terms_of_service_accepted,
            acceptance: { accept: true,
                          message: 'You must accept the terms of service.' },
            on: :create,
            if: proc { |u| !u.created_by_admin == 'true' }
  roles = %w(admin normal checkout superuser banned)
  validates :role,        inclusion: { in: roles }
  validates :view_mode,   inclusion: { in: roles << 'guest' }
  validate :view_mode_reset

  # table_name is needed to resolve ambiguity for certain queries with
  # 'includes'
  scope :active, ->() { where("role != 'banned'") }
  scope :no_phone, ->() { where('phone = ? OR phone IS NULL', '') }

  def self.search_ldap(login)
    return nil if login.blank?
    return nil unless ENV['USE_LDAP']
    LDAPHelper.new(user: login).search
  end

  def self.select_options
    User.order('last_name ASC').all
        .collect { |item| ["#{item.last_name}, #{item.first_name}", item.id] }
  end

  # ------- validations -------- #
  def skip_phone_validation?
    return true unless AppConfig.check(:require_phone)
    return true if missing_phone
    !@csv_import.nil?
  end

  def view_mode_reset
    return if role == 'superuser'
    return if role == 'admin' && view_mode != 'superuser'
    self.view_mode = role
  end
  # ------- end validations -------- #

  def name
    "#{(nickname.blank? ? first_name : nickname)} #{last_name}"
  end

  def equipment_items
    reservations.collect(&:equipment_item).flatten
  end

  def render_name
    ENV['CAS_AUTH'] ? "#{name} #{username}" : name.to_s
  end

  # ---- Reservation methods ---- #

  def overdue_reservations?
    reservations.overdue.count > 0
  end

  def due_for_checkout
    reservations.checkoutable
  end

  def due_for_checkin
    reservations.checked_out.order('due_date ASC')
  end
end
