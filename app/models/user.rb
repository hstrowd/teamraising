class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :organization_memberships, foreign_key: "member_id"
  has_many :organizations, through: :organization_memberships

  validates :first_name, :last_name, presence: true
end
