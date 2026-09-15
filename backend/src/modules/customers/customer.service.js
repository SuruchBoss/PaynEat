import { ApiError } from '../../core/ApiError.js';
import { customerRepository } from './customer.repository.js';
import { toCustomerDto } from './customer.mapper.js';

export const customerService = {
  list(filters) {
    const { rows, total } = customerRepository.findAll(filters);
    return { customers: rows.map(toCustomerDto), total };
  },

  getById(id) {
    const customer = customerRepository.findById(id);
    if (!customer) throw ApiError.notFound('ไม่พบลูกค้านี้');
    return toCustomerDto(customer);
  },

  create({ name, phone, email }) {
    if (customerRepository.findByPhone(phone)) {
      throw ApiError.conflict('เบอร์โทรนี้มีลูกค้าอยู่แล้วในระบบ');
    }
    return toCustomerDto(customerRepository.create({ name, phone, email }));
  },
};

export default customerService;
